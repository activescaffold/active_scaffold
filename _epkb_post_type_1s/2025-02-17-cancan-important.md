---
title: CanCan Important
date: "2025-02-17 14:15:18.000000000 +01:00"
permalink: "/wiki-2/cancan-important/"
---

Note that the bridge plugs into `AS#begining_of_chain`. That is the main scope from which the listing is fetched and new models are created. The bridge chains this scope taking into account your ability definitions similar to how `CanCan#load_and_authorize_resources` works, by limiting the result according to the Ability definitions.
