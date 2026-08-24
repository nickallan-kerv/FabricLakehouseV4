Root cause confirmation

Conclusion:
- Your hypothesis is consistent with observed behavior.
- The manually created lakehouse with "Lakehouse Schemas" enabled behaves correctly for medallion schema objects.

Evidence in new lakehouse (lh_medallion_nickman):
1. Notebook runs completed successfully
- Bronze run: 5f48b3a0-2f94-4dd3-82de-3bc0985289fe (Completed)
- Silver run: fb080626-4ea2-42e0-ab2d-fc5ae460d46b (Completed)
- Gold run: cf85e72c-f1df-4edb-b189-97e6f6d1a9ea (Completed)

2. Table namespace visibility
- Tables root contains: bronze, silver, gold (plus dbo)
- bronze: scores
- silver: scores, scores_quarantine
- gold: scores

Interpretation:
- The previous failure mode is strongly linked to lakehouse creation/configuration differences, specifically schema support.
- Running the same notebooks against a schema-enabled lakehouse resolves the schema interpretation/visibility problem.

Action going forward:
- Keep using lh_medallion_nickman as the active target.
- Keep lh_medallion_nickmanv1 untouched until final cleanup.
