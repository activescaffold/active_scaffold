---
title: "500 Internal Error? That’s not helpful!"
date: "2025-02-17 14:34:28.000000000 +01:00"
---

Yeah, you’re right, it’s not really. This error message is designed to walk a fine line between being useful for developers and for end-users, kind of like Gmail’s error messages. The trick here is to know, as a developer, that a 500 response means that an exception happened in your code. Check out the last bit of logs/development.log right after you see a 500 response, and you’ll get to see the actual error.
