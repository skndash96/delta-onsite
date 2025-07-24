from flask import Flask
from os import environ

port = environ.get('PORT', 5000)
dept = environ.get('DEPT')
instance = environ.get('INSTANCE')

app = Flask(__name__)

if not dept:
  raise ValueError("Environment variable 'DEPT' is not set")

if not instance:
  raise ValueError("Environment variable 'INSTANCE' is not set")

@app.route('/')
def hello_world():
    return 'Hello World from {} {}'.format(dept, instance)

if __name__ == '__main__':
    app.run(port=port)