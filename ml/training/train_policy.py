"""Train a compact behavior-cloning policy from recorded rover states/actions."""
from __future__ import annotations
import argparse, json
from pathlib import Path
import joblib
import numpy as np
from sklearn.impute import SimpleImputer
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import GroupShuffleSplit
from sklearn.metrics import classification_report

FEATURES = ["front_distance_cm","left_distance_cm","right_distance_cm","target_distance_cm","target_angle_deg","speed_cm_s","rssi_dbm","previous_action_id"]

def load(path):
    rows=[json.loads(x) for x in Path(path).read_text(encoding="utf-8").splitlines() if x.strip()]
    X=[]; y=[]; groups=[]
    action_ids={"STOP":0,"FORWARD":1,"LEFT":2,"RIGHT":3,"REVERSE":4}
    for r in rows:
        X.append([r.get(f) if f != "previous_action_id" else action_ids.get(r.get("previous_action"), -1) for f in FEATURES])
        y.append(r["action"]); groups.append(r.get("session_id","unknown"))
    return np.asarray(X,float), np.asarray(y), np.asarray(groups)

def main():
    p=argparse.ArgumentParser(); p.add_argument("--input",required=True); p.add_argument("--output",required=True); p.add_argument("--test-size",type=float,default=.2); a=p.parse_args()
    X,y,g=load(a.input)
    if len(np.unique(y))<2: raise SystemExit("Need at least two actions.")
    if len(np.unique(g))<2: raise SystemExit("Need at least two independent recording sessions.")
    tr,te=next(GroupShuffleSplit(n_splits=1,test_size=a.test_size,random_state=42).split(X,y,g))
    model=Pipeline([("imputer",SimpleImputer(strategy="median")),("scale",StandardScaler()),("policy",MLPClassifier(hidden_layer_sizes=(64,32),max_iter=500,early_stopping=True,random_state=42))])
    model.fit(X[tr],y[tr]); pred=model.predict(X[te]); report=classification_report(y[te],pred,output_dict=True,zero_division=0)
    out=Path(a.output); out.parent.mkdir(parents=True,exist_ok=True); joblib.dump({"model":model,"features":FEATURES,"actions":sorted(np.unique(y).tolist()),"metrics":report},out)
    print(json.dumps(report,indent=2)); print(f"saved {out}")
if __name__=="__main__": main()
