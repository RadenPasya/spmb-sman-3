from app import app

# Vercel membutuhkan variabel 'app' ini untuk fungsi Serverless
if __name__ == "__main__":
    app.run()
