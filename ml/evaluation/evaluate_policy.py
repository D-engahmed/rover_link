"""Evaluate a behavior-cloning policy on unseen recording sessions."""
from __future__ import annotations
import argparse,json
from pathlib import Path
import joblib,numpy as np
from sklearn.model_selection import GroupShuffleSplit
from sklearn.metrics import classification_report,confusion_matrix

ACTIONS={"STOP":0,"FORWARD":1,"LEFT":2,"RIGHT":3,"REVERSE":4}
def main():
 p=argparse.ArgumentParser(); p.add_argument("--dataset",required=True); p.add_argument("--model",required=True); p.add_argument("--output",required=True); a=p.parse_args()
 art=joblib.load(a.model); rows=[json.loads(x) for x in Path(a.dataset).read_text(encoding="utf-8").splitlines() if x.strip()]; feats=art["features"]
 X=[];y=[];g=[]
 for r in rows:
  X.append([r.get(f) if f!="previous_action_id" else ACTIONS.get(r.get("previous_action"),-1) for f in feats]); y.append(r["action"]); g.append(r.get("session_id","unknown"))
 X=np.asarray(X,float);y=np.asarray(y);g=np.asarray(g)
 if len(np.unique(g))<2: raise SystemExit("Need at least two independent sessions.")
 _,te=next(GroupShuffleSplit(n_splits=1,test_size=.2,random_state=42).split(X,y,g)); pred=art["model"].predict(X[te]); labels=sorted(set(y[te])|set(pred)); result={"samples":int(len(te)),"report":classification_report(y[te],pred,output_dict=True,zero_division=0),"labels":labels,"confusion_matrix":confusion_matrix(y[te],pred,labels=labels).tolist(),"warning":"Evaluate on independent physical sessions; row-level random splits can leak environment and temporal state."}; Path(a.output).write_text(json.dumps(result,indent=2),encoding="utf-8"); print(json.dumps(result,indent=2))
if __name__=="__main__": main()
