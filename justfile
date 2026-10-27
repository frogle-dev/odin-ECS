target := "build/ecs"

dbg action sanitizer="":
    odin {{action}} . -out:{{target}} -debug {{ if sanitizer == "" { "" } else { "-sanitize:" + sanitizer } }} -vet -strict-style -custom-attribute:system,archetype
