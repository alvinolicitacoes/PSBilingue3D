extends Node3D
## Stylized 3D character meshes made from Godot primitives; no flat sprites.
## Both characters are original low-poly interpretations of the supplied reference.

func mat(hex: String) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color(hex)
    m.roughness = 0.78
    return m

func ball(label: String, pos: Vector3, scale_: Vector3, color: String) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := SphereMesh.new()
    mesh.radial_segments = 20
    mesh.rings = 12
    node.mesh = mesh
    node.material_override = mat(color)
    node.position = pos
    node.scale = scale_
    add_child(node)
    return node

func block(label: String, pos: Vector3, size_: Vector3, color: String) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := BoxMesh.new()
    mesh.size = size_
    node.mesh = mesh
    node.material_override = mat(color)
    node.position = pos
    add_child(node)
    return node

func cone(label: String, pos: Vector3, radius: float, height_: float, color: String) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.04
    mesh.bottom_radius = radius
    mesh.height = height_
    mesh.radial_segments = 12
    node.mesh = mesh
    node.material_override = mat(color)
    node.position = pos
    add_child(node)
    return node

func build_pietro() -> void:
    # Front faces +Z; curly dark hair, warm brown skin, white outfit.
    ball("Torso camisa branca",Vector3(0,1.24,0),Vector3(0.39,0.49,0.24),"f7f7f2")
    block("Gola esquerda",Vector3(-0.13,1.64,0.20),Vector3(0.19,0.12,0.06),"dce5e7")
    block("Gola direita",Vector3(0.13,1.64,0.20),Vector3(0.19,0.12,0.06),"dce5e7")
    ball("Pescoço",Vector3(0,1.75,0),Vector3(0.14,0.17,0.14),"b86b3b")
    ball("Cabeça",Vector3(0,2.08,0.05),Vector3(0.46,0.48,0.40),"bb7447")
    for side in [-1.0,1.0]:
        ball("Orelha",Vector3(side*0.44,2.06,0.04),Vector3(0.10,0.16,0.10),"b86b3b")
        ball("Braço",Vector3(side*0.44,1.28,0),Vector3(0.12,0.38,0.14),"bd7546")
        ball("Manga",Vector3(side*0.43,1.53,0),Vector3(0.16,0.18,0.17),"f8f8f4")
        ball("Perna",Vector3(side*0.19,0.43,0),Vector3(0.15,0.36,0.15),"b66e40")
        ball("Shorts",Vector3(side*0.19,0.82,0),Vector3(0.20,0.23,0.21),"f2f1ec")
        ball("Tênis",Vector3(side*0.19,0.13,0.14),Vector3(0.18,0.13,0.30),"f7f8fc")
        ball("Olho branco",Vector3(side*0.19,2.13,0.40),Vector3(0.125,0.14,0.065),"fffaf1")
        ball("Íris castanha",Vector3(side*0.19,2.13,0.46),Vector3(0.073,0.085,0.034),"59311d")
        ball("Pupila",Vector3(side*0.19,2.13,0.485),Vector3(0.038,0.050,0.020),"151515")
        ball("Sobrancelha",Vector3(side*0.19,2.32,0.35),Vector3(0.14,0.032,0.038),"30201b")
    ball("Nariz",Vector3(0,2.02,0.46),Vector3(0.08,0.07,0.07),"a45e35")
    ball("Sorriso",Vector3(0,1.88,0.405),Vector3(0.19,0.045,0.035),"512b27")
    ball("Dentes",Vector3(0,1.895,0.44),Vector3(0.135,0.023,0.015),"fff7ed")
    # Individually sculpted curls give a distinct silhouette.
    for i in range(36):
        var angle := TAU*float(i%12)/12.0
        var ring := float(i/12)
        var radius := 0.25 + ring*0.085
        var y := 2.43 + 0.14*sin(angle*2.0) - ring*0.035
        ball("Cacho %02d" % i,Vector3(cos(angle)*radius,y,sin(angle)*radius+0.015),Vector3(0.14,0.13,0.14),"251a17" if i%3 else "38231b")
    for i in range(8):
        var a := TAU*float(i)/8.0
        ball("Cacho alto %02d" % i,Vector3(cos(a)*0.20,2.60,sin(a)*0.20),Vector3(0.15,0.15,0.15),"2c1d18")
    ball("Pingente dourado",Vector3(0,1.40,0.255),Vector3(0.045,0.065,0.03),"e8b94e")

func build_thor() -> void:
    # Fawn-and-white French bulldog: stocky body, upright ears, dark muzzle.
    ball("Corpo Thor",Vector3(0,0.53,-0.08),Vector3(0.38,0.37,0.56),"d7a06b")
    ball("Peito branco",Vector3(0,0.49,0.37),Vector3(0.28,0.31,0.15),"f7e9d5")
    ball("Cabeça Thor",Vector3(0,0.92,0.39),Vector3(0.38,0.37,0.32),"c9925d")
    ball("Faixa branca",Vector3(0,1.04,0.66),Vector3(0.095,0.26,0.09),"f7e6d1")
    ball("Focinho escuro",Vector3(0,0.77,0.68),Vector3(0.28,0.20,0.17),"403536")
    ball("Nariz",Vector3(0,0.85,0.84),Vector3(0.12,0.09,0.08),"19191d")
    for side in [-1.0,1.0]:
        cone("Orelha erguida",Vector3(side*0.25,1.33,0.32),0.19,0.49,"bd8556")
        cone("Interior orelha",Vector3(side*0.25,1.36,0.45),0.095,0.30,"b86c73")
        ball("Olho",Vector3(side*0.19,1.01,0.665),Vector3(0.085,0.095,0.055),"242023")
        ball("Brilho olho",Vector3(side*0.17,1.045,0.716),Vector3(0.026,0.026,0.016),"ffffff")
        ball("Pata dianteira",Vector3(side*0.23,0.20,0.30),Vector3(0.13,0.23,0.16),"f4e2cb")
        ball("Pata traseira",Vector3(side*0.26,0.20,-0.43),Vector3(0.17,0.22,0.19),"d8a16e")
    ball("Língua rosa",Vector3(0,0.63,0.79),Vector3(0.085,0.12,0.04),"f08c9a")
    ball("Rabinho",Vector3(0,0.64,-0.63),Vector3(0.10,0.10,0.13),"bd8659")
