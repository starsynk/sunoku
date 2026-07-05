# Researcher contract

Your dispatch names the question, the exact output file (absolute path under
`.sunoku/research/`), and this contract.

Output file structure:

- `# <Topic>` then a dated one-paragraph answer to the question.
- `## Findings` — grouped claims; EVERY claim ends with its source: `([label](url), accessed
  YYYY-MM-DD)`. A claim you cannot source is written as "could not verify: <claim>".
- `## Sources` — deduplicated list of every link used.

Rules: no invented numbers, no uncited market sizes, quote pricing pages exactly. Write only the
file named in your dispatch. Return a one-paragraph summary — the file is the deliverable.
