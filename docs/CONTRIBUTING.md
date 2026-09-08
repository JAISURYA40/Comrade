
# 🙏 **Acknowledgements & Disclaimer**  

First off, thank you for even considering contributing to **Comrade**. This project exists because of passionate people like you who believe in something bigger than themselves.  

### **Before you contribute**  
I just want to be upfront about a few things:  
- Any contributions you make - whether it’s code, ideas, or assets `become part of Comrade`. You won’t own the rights to them, but your impact will live on in every user who benefits from your work.  
- `Comrade will always be free and open-source.` No hidden paywalls, no selling out. Just a tool to help people take control of their screen time.  
- I don’t make much from this project, and as much as I’d love to share donations, they just don’t exist in any meaningful way. What I `can` do is give `credit` where it’s due. If there’s a way to acknowledge your work, I’ll make sure it happens.  
- I might update these terms down the road, not to take anything away from you, but to protect the project and keep it `truly open and free`  

### **If this doesn’t sit right with You**  
I get it. If you’re not comfortable with these terms, _**please don’t feel discouraged**_. You can still open an issue or request a feature, and I’ll do my best to bring your idea to life. Your voice still matters.  

And just so you know `Comrade will never be abandoned.` As long as I’m around, I’ll keep improving it. That’s my promise.  

Thank you for being here. <br> You matter more than you know 💙

---

# 📝 How to contribute

### 1. Open an Issue:

- Before contributing, please open an issue to discuss your proposed changes or feature implementation. This step ensures that your contribution aligns with the project’s goals and that your efforts are necessary and valued.

### 2. Branching Strategy:

- Development occurs on the `dev` branch. Please fork the repository and create your branch from `dev`.

### 3. Make Changes:

- Implement your changes and commit them to your branch.

### 4. Submit a Pull Request:

- Once your changes are ready, submit a pull request to the `dev` branch of the repository. Be sure to reference any issues that your pull request addresses in the description.

### 5. Review and Merge:

- Your pull request will be reviewed, and feedback will be provided. Upon approval, your pull request will be merged into the `dev` branch and included in the next release of Comrade.

---

# 🛠️ Building from source

Learn how to build Comrade from source.

1. Setup the Flutter environment for your [platform](https://docs.flutter.dev/get-started/install)

2. Clone the repository

   ```sh
   git clone https://github.com/akaMrNagar/Comrade.git && cd comrade
   ```

3. Get dependencies

   ```sh
   flutter pub get
   ```

4. Generate temporary files

   ```sh
   dart run build_runner build -d
   ```

5. Build the APK

   ```sh
   flutter build apk
   ```
