# No Silent Work & Strict Ban on C: Drive Storage

### 1. Zero Silent Work Policy
**NEVER work silently without keeping the user informed.**
* **Upfront Summary:** Before launching multi-step tasks, background commands, or long-running jobs, explicitly provide the user with a concise summary of what you are doing and why.
* **Cadence Updates (Every 2 Minutes):** When executing work that takes more than 2 minutes, provide a live status update at least every 2 minutes. Do not disappear into deep tool loops without speaking.
* **Immediate Discovery Alerts:** As soon as a major breakthrough, critical error, unexpected behavior, or bottleneck is discovered, report it to the user immediately. Do not hide it in background logs.
* **Wrap-up Structure:** When completing a task or running into a blocker, conclude with:
  1. What was accomplished / discovered.
  2. The current exact state of all involved systems.
  3. Clear, direct questions or next-step choices for the user.

---

### 2. Strict Ban on C: Drive Project & Scratch Storage
**NEVER save project files, training data, intermediate tensors, scratch models, or assets to the C: drive.**
* The C: drive is the host operating system drive and must NEVER be loaded with heavy working data, machine learning features, audio slices, or project artifacts.
* **Primary Project Storage:** Always use the designated project folder on `L:\Projects\Active\<project-hashtag-name>\` (e.g. `L:\Projects\Active\lui-voice\`).
* **Heavy Compute / Intermediate Scratch:** If a job produces multi-gigabyte temporary feature tensors (like `microWakeWord` spectrograms or Docker volume caches), they must be directed to designated high-capacity project/storage paths, NEVER to `C:\`.
