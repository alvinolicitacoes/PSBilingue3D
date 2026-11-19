# Integração de modelos 3D

- `scripts/world.gd` agora instancia edifícios, vegetação, fonte, Pietro e um cão provisório dos GLBs fornecidos.
- As atividades e scripts de jogos originais foram mantidos.
- A função `_model` normaliza altura e centraliza a base dos modelos.
- O cão Dog_01 **não foi confirmado como bulldog francês**.
- Cute Boy não possui rig; portanto animações Walking/Running de outro esqueleto não foram aplicadas.
- A iluminação foi reduzida.
- Teste no Godot 4.7: os modelos podem exigir ajuste de rotação/colisão após inspeção visual.
- Não foi possível executar o editor Godot neste ambiente; a integração ainda não está validada em runtime.
