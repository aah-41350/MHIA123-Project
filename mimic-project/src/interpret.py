import shap
import torch
import matplotlib.pyplot as plt

def generate_shap_plots(model, X_train, X_test, feature_names, device=None):
    """Generates global and local interpretability plots."""
    if device is None:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    # Wrapper to convert model output to probabilities for SHAP
    def model_predict(data):
        model.eval()
        with torch.no_grad():
            data_tensor = torch.FloatTensor(data).to(device)
            return torch.sigmoid(model(data_tensor)).cpu().numpy()

    # Use 100 samples from training as background
    explainer = shap.KernelExplainer(model_predict, X_train[:100])
    shap_values = explainer.shap_values(X_test[:50])

    # Summary Plot
    plt.figure(figsize=(10, 6))
    shap.summary_plot(shap_values, X_test[:50], feature_names=feature_names, show=False)
    plt.title("Preoperative Risk Factors (SHAP Values)")
    plt.savefig('models/shap_summary.png')
    plt.close()
    
    return explainer, shap_values