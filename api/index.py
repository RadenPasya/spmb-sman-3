import sys
import os

# Menambahkan root directory ke sys.path
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from app import app

if __name__ == '__main__':
    app.run()
