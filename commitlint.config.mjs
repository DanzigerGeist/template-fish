export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    // Disabled because machine-generated commit bodies legitimately exceed 100
    // characters and cannot be reflowed: Dependabot appends `dependency-type:`
    // / `update-type:` metadata trailers, and without this every Dependabot PR
    // fails the Commits gate. The subject-line rules are the ones that matter
    // here anyway -- they are what cocogitto reads to decide the version bump.
    "body-max-line-length": [0],
  },
};
