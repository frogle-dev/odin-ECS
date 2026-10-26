target := "build/ecs"

dbg action sanitizer="":
    odin {{action}} . -out:{{target}} -debug {{ if sanitizer == "" { "" } else { "-sanitize:" + sanitizer } }} -custom-attribute:system
