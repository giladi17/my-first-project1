from flask import Flask

# יצירת מופע של האפליקציה
app = Flask(__name__)

# הגדרת הנתיב הראשי של האפליקציה
@app.route('/')
def hello():
    return "hello gilad"

# הרצת השרת
if __name__ == '__main__':
    # host='0.0.0.0' מאפשר גישה גם מבחוץ (שימושי אם תרצה להריץ את זה בתוך קונטיינר Docker בהמשך)
    app.run(debug=True, host='0.0.0.0', port=5000)