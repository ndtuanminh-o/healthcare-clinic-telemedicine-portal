# Normalization Verification & Functional Dependency Analysis
## Formal Proofs for 1NF, 2NF, 3NF, and BCNF
### Topic 05: Healthcare Clinic & Telemedicine Management System | PTIT
**Project:** Clinic Management & Telemedicine Portal | **Team:** G5 - Pingo  

---

## 1. Normalization Objectives & Formal Definitions

Normalization guarantees relational database integrity, eliminates data anomalies (insertion, update, deletion anomalies), and minimizes storage redundancy.

This verification provides formal mathematical proofs that all eleven (11) relational tables in the schema satisfy:
- **First Normal Form (1NF):** Every attribute domain contains only atomic (indivisible) values, and there are no repeating groups or multivalued attributes.
- **Second Normal Form (2NF):** The relation is in 1NF and every non-prime attribute is fully functionally dependent on the entire primary key (no partial functional dependencies).
- **Third Normal Form (3NF):** The relation is in 2NF and no non-prime attribute is transitively dependent on the primary key (for every functional dependency $X \rightarrow Y$, either $X$ is a superkey or $Y$ is a prime attribute).

---

