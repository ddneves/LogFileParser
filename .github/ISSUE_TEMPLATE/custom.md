---
name: Custom issue template
about: Describe this issue template's purpose here.
title: ''
labels: bug
assignees: ddneves

body:
  - type: input
    id: context
    attributes:
      label: Context
      description: Please provide us some context.
    validations:
      required: false
  - type: input
    id: problem
    attributes:
      label: Problem Statement
      description: What are we trying to solve with this ADR? Why is it required?
    validations:
      required: true
