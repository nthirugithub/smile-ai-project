import pandas as pd

main_df = pd.read_csv("dataset/smile_dataset_labeled.csv")
doctor_df = pd.read_csv("dataset/doctor_features.csv")

combined_df = pd.concat(
    [main_df, doctor_df],
    ignore_index=True
)

combined_df.to_csv(
    "dataset/combined_dataset.csv",
    index=False
)

print(f"Original dataset: {len(main_df)}")
print(f"Doctor dataset: {len(doctor_df)}")
print(f"Combined dataset: {len(combined_df)}")