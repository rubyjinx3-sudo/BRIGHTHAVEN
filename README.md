# 🌪️ Brighthaven: Typhoon Survival

**An Educational Roblox Survival Tycoon Game for Grade 3 Mathematics**

Brighthaven: Typhoon Survival is a Roblox-based educational survival tycoon game designed to support Grade 3 learners in developing whole-number division, chunking (partial quotients), remainder reasoning, and basic budgeting skills.

Aligned with the **DepEd MATATAG Mathematics Grade 3 Curriculum – Module 2: Division & Money**, the game places learners in the role of Junior Logistics Resource Captains tasked with helping a coastal town prepare for and recover from recurring typhoon emergencies.

Through interactive tutorials, mathematical challenges, resource allocation, and survival missions, learners can practice mathematical concepts in an engaging and practical environment.

---

## 🎯 Project Objectives

- Strengthen Grade 3 learners' understanding of whole-number division.
- Introduce and reinforce the chunking or partial quotients strategy.
- Develop reasoning skills when working with division remainders.
- Integrate basic budgeting and resource allocation into gameplay.
- Provide an interactive learning environment through typhoon survival scenarios.
- Track learner performance and progression through in-game analytics.

## 🎮 Key Features

### 1. Player Onboarding and Foundational Tutorials

The game introduces three interactive tutorial activities:

- **Equal Sharing:** Distribute relief packs equally among evacuation shelters.
- **Multiples and Skip Counting:** Complete a flood boardwalk obstacle course using skip-counting concepts.
- **Factoring and Arrays:** Arrange crates into equal rows and columns to understand factors and multiplication arrays.

### 2. Core Division Gameplay

Brighthaven provides interactive mathematical activities through:

- **Equal Share Engine:** Practice dividing resources into equal groups.
- **Chunking Console:** Solve division problems using partial quotients.
- **Factor Assist Panel:** Review multiples, factors, and arrays to identify useful division strategies.
- **Remainder Handler:** Interpret remainders based on the context of resource distribution.
- **Multiplication Verification Gate:** Verify division answers using multiplication before completing a mission.

### 3. Storm Missions and Survival Economy

Players participate in three progressive storm levels:

| Level | Scenario | Learning Focus |
|---|---|---|
| Level 1 | Tropical Storm | Whole-number division using divisors 6, 7, 8, and 9, with dividends up to 100 |
| Level 2 | Category 3 Typhoon | Two- to three-digit division, remainders, and relief budgeting |
| Level 3 | Super Typhoon | Multi-step money and resource distribution problems |

Additional gameplay features include:

- Storm briefings and mission launching.
- Coin rewards and community upgrades.
- Watercraft improvements and shelter fortification.
- Relief supply missions and rescue activities.
- Post-storm reconstruction and replayable randomized cycles.

### 4. Automated Night Curfew and Safe-Zone Recall

The game includes an automated in-game safety protocol from **9:00 PM to 7:00 AM**.

During curfew:
- Outdoor rescue missions and mission boards are locked.
- Captain Kapa displays an emergency safety warning.
- Players are automatically recalled to the Base House safe zone.
- Indoor activities remain available during curfew hours.

### 5. Player Analytics and Progression

The Analytics Board allows players to review their gameplay progress, including:

- Missions completed.
- Correct answers.
- Coins earned.
- Storms survived.
- Hints used.
- Total time played.
- XP progress and rank.
- Overall answer accuracy.
- Multiplication Verification Gate pass rate.
- Average retries per mission.

---

## 🏗️ System Architecture

Brighthaven operates within the Roblox platform using its native client-server architecture.

The system is organized into four major functional modules:

| Module | Description |
|---|---|
| Module 1 – Player Onboarding and Authentication | Player access, profile loading, and foundational tutorials |
| Module 2 – Core Division Gameplay | Equal sharing, chunking, factor assistance, remainder handling, and multiplication verification |
| Module 3 – Storm Mission and Economy | Mission launching, survival budgeting, upgrades, and night curfew |
| Module 4 – Player Analytics Board | Player statistics, XP progression, rank, and accuracy breakdown |

### Technical Architecture

- Client-side interfaces handle player interaction and display.
- Server-side Luau modules process and validate important game operations.
- RemoteEvents and RemoteFunctions communicate player actions to server-side systems.
- Roblox DataStoreService stores player progression and profile information.
- Server-side validation protects calculations, rewards, currency updates, progression, and cooldowns.

---

## 🛠️ Technologies and Development Tools

| Technology / Tool | Purpose |
|---|---|
| Roblox Studio | Game development and testing environment |
| Luau | Scripting language |
| Roblox Engine | Game runtime, rendering, physics, and interfaces |
| Roblox DataStoreService | Player data persistence |
| RemoteEvents and RemoteFunctions | Client-server communication |
| Rojo | Roblox project synchronization and development workflow |
| Aftman / Rokit | Development tool configuration |

---

## 💻 Repository Structure

```text
BRIGHTHAVEN/
│
├── .vscode/
│
├── src/
│   └── Game source files
│
├── .gitignore
├── README.md
├── aftman.toml
├── default.project.json
├── rokit.toml
└── syncback.project.json
```

---

## 🚀 Getting Started

### Prerequisites

Before working with the project, prepare the following:

- A Roblox account.
- Roblox Studio.
- Git.
- The development tools configured in the repository's Aftman/Rokit configuration files.
- Rojo for project synchronization.

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/rubyjinx3-sudo/BRIGHTHAVEN.git
   ```

2. Navigate to the project directory:

   ```bash
   cd BRIGHTHAVEN
   ```

3. Install or configure the development tools specified by the repository.

4. Open the project using the configured Rojo and Roblox Studio workflow.

5. Run the game in Roblox Studio to test the implemented features.

*Note: Confirm the exact tool installation and synchronization commands against the team's development environment before publishing this README as final setup documentation.*

---

## 🧪 Testing and Validation

The project undergoes functional testing and usability evaluation to assess its educational features, gameplay experience, and system behavior.

Evaluation areas include:

- Mathematical activity functionality.
- Tutorial clarity and accessibility.
- Division and remainder validation.
- Player interface usability.
- Gameplay engagement.
- System performance and reliability.
- Player progress and data persistence.

Usability evaluation findings and testing evidence should be documented separately in the project's testing and validation deliverables.

---

## 🔐 Privacy and Security

Brighthaven follows the privacy and security requirements defined in its Software Requirements Specification.

- No sensitive personal information, such as real names, home addresses, contact numbers, or exact locations, is collected or stored.
- Player progression is associated with the automatically generated Roblox `Player.UserId`.
- Important calculations and game-state changes are validated on the server.
- Player profile access and updates are restricted to the authenticated player.

---

## 📚 Educational Reference

The project is aligned with the Department of Education (Philippines) **MATATAG Mathematics Curriculum for Grade 3 – Module 2: Division & Money**.

Official curriculum reference:

https://www.deped.gov.ph/wp-content/uploads/MATATAG-Mathematics-CG-Grades1-4-and-7.pdf

Roblox Creator Hub:

https://create.roblox.com/docs

---

## 👥 Development Team

**Team 2526-sem2-it332-02**  
College of Computer Studies  
Cebu Institute of Technology – University

### Project Adviser

Dr. Chris Jordan G. Aliac

---

## 🔗 Project Links

- **GitHub Repository:** https://github.com/rubyjinx3-sudo/BRIGHTHAVEN
- **Deployed Roblox Game:** To be added once the published experience URL is available.

---

*Brighthaven: Typhoon Survival – Helping young learners build mathematical skills through interactive learning and typhoon survival challenges.*
