from flask import Flask, redirect, url_for, render_template
from config import Config
from routes.appointment_routes import appointment_bp
from routes.clinical_routes import clinical_bp
from routes.prescription_routes import prescription_bp
from routes.dashboard_routes import dashboard_bp

app = Flask(__name__)
app.config.from_object(Config)

app.register_blueprint(appointment_bp)
app.register_blueprint(clinical_bp)
app.register_blueprint(prescription_bp)
app.register_blueprint(dashboard_bp)

@app.route("/")
def index():
    return redirect(url_for("appointment.booking"))

@app.route("/doctor")
def doctor():
    return render_template("doctor.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
