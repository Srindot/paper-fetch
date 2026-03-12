# Research Papers Index

- **[AERMANI-VLM: Structured Prompting and Reasoning for Aerial Manipulation with Vision Language Models](AERMANIVLM_Structured_Prompting_and_Reasoning_for__2026/Mishra_2026.pdf)** (2026) - Sarthak Mishra; Rishabh Dev Yadav; Avirup Das; Saksham Gupta; Wei Pan; Spandan Roy | [📄 Markdown Notes](AERMANIVLM_Structured_Prompting_and_Reasoning_for__2026/Mishra_2026.md)

    **Abstract:** (VLMs) has sparked growing interest in robotic control, where natural language can express the operation goals while visual feedback links perception to action. However, directly deploying VLM-driven policies on aerial manipulators remains unsafe and unreliable since the generated actions are often inconsistent, hallucination-prone, and dynamically infeasible for flight. In this work, we present AERMANI-VLM, the first framework to adapt pretrained VLMs for aerial manipulation by separating high-level reasoning from low-level control, without any taskspecific fine-tuning. Our framework encodes natural language instructions, task context, and safety constraints into a structured prompt that guides the model to generate a step-by-step reasoning trace in natural language. This reasoning output is used to select from a predefined library of discrete, flightsafe skills, ensuring interpretable and temporally consistent execution. By decoupling symbolic reasoning from physical action, AERMANI-VLM mitigates hallucinated commands and prevents unsafe behavior, enabling robust task completion. We validate the framework in both simulation and hardware on diverse multi-step pick-and-place tasks, demonstrating strong generalization to previously unseen commands, objects, and environment. Website: https://sites.google.com/view/aermani-vlm

    **BibTeX:**
    ```bibtex
    @article{Mishra_2026,
      title={AERMANI-VLM: Structured Prompting and Reasoning for Aerial Manipulation with Vision Language Models},
      author={Sarthak Mishra and  Rishabh Dev Yadav and  Avirup Das and  Saksham Gupta and  Wei Pan and  Spandan Roy},
      year={2026},
      url={https://arxiv.org/pdf/2511.01472}
    }
    ```

