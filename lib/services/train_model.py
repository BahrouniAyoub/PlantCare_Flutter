import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier
from joblib import dump

# Load dataset
df = pd.read_csv('TARP.csv')

# Select relevant columns
features = ['Soil Moisture', 'Temperature', ' Soil Humidity', 'ph', 'rainfall', 'Air humidity (%)']
target = 'Status'

# Drop rows with any NaN in selected columns
df = df[features + [target]].dropna()

# Define X and y
X = df[features]
y = df[target]

# Split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train KNN model
knn = KNeighborsClassifier(n_neighbors=5, weights='distance')
knn.fit(X_train, y_train)

# Evaluate and save model
print("Accuracy:", knn.score(X_test, y_test))
dump(knn, 'knn_model.joblib')
