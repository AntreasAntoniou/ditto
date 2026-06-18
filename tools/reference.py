import _compat  # noqa
import json, numpy as np, torch
from transformers import AutoConfig, AutoTokenizer
from transformers.dynamic_module_utils import get_class_from_dynamic_module
from safetensors.torch import load_file
P = "models/ogma-small"
tok = AutoTokenizer.from_pretrained(P, trust_remote_code=True)
cfg = AutoConfig.from_pretrained(P, trust_remote_code=True)
model = get_class_from_dynamic_module("ogma_model.OgmaModel", P)(cfg).eval()
model.load_state_dict(load_file(f"{P}/model.safetensors"), strict=False)
samples = [("the quick brown fox","doc"), ("hello world","qry"), ("python ValueError stack trace","doc")]
out = []
for text, task in samples:
    ids = tok([text])["input_ids"][0]
    with torch.no_grad():
        v = model.embed([text], task=task)
    v = (v[0].numpy() if hasattr(v,'__getitem__') else np.asarray(v)).reshape(-1)
    out.append({"text": text, "task": task, "ids": ids, "vec_head": [round(float(x),5) for x in v[:6]], "norm": round(float(np.linalg.norm(v)),5)})
json.dump(out, open("reference.json","w"), indent=1)
for o in out: print(o["text"], "| task", o["task"], "| ids", o["ids"], "| head", o["vec_head"], "| norm", o["norm"])
