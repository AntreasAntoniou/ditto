import _compat  # noqa
import sys, torch, numpy as np
import torch.nn.functional as F
from transformers import AutoConfig, AutoTokenizer
from transformers.dynamic_module_utils import get_class_from_dynamic_module
from safetensors.torch import load_file
import coremltools as ct

P = sys.argv[1]; name = P.split("/")[-1]
cfg = AutoConfig.from_pretrained(P, trust_remote_code=True)
tok = AutoTokenizer.from_pretrained(P, trust_remote_code=True)
model = get_class_from_dynamic_module("ogma_model.OgmaModel", P)(cfg).eval()
model.load_state_dict(load_file(f"{P}/model.safetensors"), strict=False)

class Wrap(torch.nn.Module):
    def __init__(s, m): super().__init__(); s.m = m
    def forward(s, input_ids, attention_mask, task_token_ids):
        v = s.m(input_ids=input_ids, attention_mask=attention_mask, task_token_ids=task_token_ids)
        return F.normalize(v, p=2, dim=1)

wrap = Wrap(model).eval()
enc = tok(["the quick brown fox"], return_tensors="pt", padding=True)
ids = enc["input_ids"].int()
mask = enc.get("attention_mask", torch.ones_like(enc["input_ids"])).int()
task = torch.tensor([5], dtype=torch.int32)  # DOC
with torch.no_grad():
    ref = wrap(ids, mask, task).numpy()
traced = torch.jit.trace(wrap, (ids, mask, task), strict=False)
sl = ct.RangeDim(lower_bound=1, upper_bound=1024, default=16)
ml = ct.convert(traced,
    inputs=[ct.TensorType(name="input_ids", shape=(1, sl), dtype=np.int32),
            ct.TensorType(name="attention_mask", shape=(1, sl), dtype=np.int32),
            ct.TensorType(name="task_token_ids", shape=(1,), dtype=np.int32)],
    outputs=[ct.TensorType(name="embedding")],
    minimum_deployment_target=ct.target.macOS13, compute_units=ct.ComputeUnit.ALL)
ml.save(f"models/{name}.mlpackage")
pred = ml.predict({"input_ids": ids.numpy().astype(np.int32),
                   "attention_mask": mask.numpy().astype(np.int32),
                   "task_token_ids": task.numpy().astype(np.int32)})
cl = np.asarray(pred["embedding"]).reshape(-1)
cos = float(np.dot(ref.reshape(-1), cl) / (np.linalg.norm(ref) * np.linalg.norm(cl)))
print(f"{name}: dim={cl.shape[0]} parity_cosine={cos:.5f}")
