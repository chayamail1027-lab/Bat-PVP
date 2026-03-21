<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>Hex-A-Gone: 3min Edition (Enhanced)</title>
    <style>
        body { margin: 0; overflow: hidden; background: #81ecec; font-family: 'Segoe UI', Tahoma, sans-serif; }
        #ui-layer { position: absolute; inset: 0; pointer-events: none; }
        #timer { position: absolute; top: 20px; left: 50%; transform: translateX(-50%); font-size: 36px; font-weight: 900; color: #2c3e50; background: rgba(255,255,255,0.8); padding: 5px 35px; border-radius: 50px; border: 4px solid #fbc531; box-shadow: 0 4px 15px rgba(0,0,0,0.2); }
        #kill-log { position: absolute; bottom: 30px; left: 30px; display: flex; flex-direction: column-reverse; }
        .log { background: rgba(45, 52, 54, 0.8); color: white; padding: 8px 18px; margin-top: 5px; border-radius: 20px; font-size: 14px; font-weight: bold; border-left: 5px solid #ff7675; animation: logAnim 3s forwards; }
        @keyframes logAnim { 0% { opacity: 0; transform: translateX(-30px); } 10% { opacity: 1; transform: translateX(0); } 90% { opacity: 1; } 100% { opacity: 0; } }
        
        #kill-feed { position: absolute; bottom: 100px; left: 50%; transform: translateX(-50%); display: flex; flex-direction: column-reverse; align-items: center; pointer-events: none; z-index: 10; }
        .kill-msg { background: rgba(214, 48, 49, 0.9); color: white; padding: 10px 25px; margin-top: 10px; border-radius: 30px; font-size: 20px; font-weight: 900; text-transform: uppercase; letter-spacing: 1px; box-shadow: 0 4px 10px rgba(0,0,0,0.3); border: 2px solid #fff; animation: killAnim 4s forwards; }
        @keyframes killAnim { 0% { opacity: 0; transform: translateY(20px) scale(0.8); } 5% { opacity: 1; transform: translateY(0) scale(1.1); } 10% { transform: scale(1); } 90% { opacity: 1; } 100% { opacity: 0; transform: translateY(-20px); } }

        #overlay { position: absolute; inset: 0; background: radial-gradient(circle, rgba(129,236,236,0.4) 0%, rgba(45,52,54,0.9) 100%); display: flex; flex-direction: column; justify-content: center; align-items: center; z-index: 100; color: white; backdrop-filter: blur(8px); }
        #title { font-size: 90px; margin-bottom: 0; text-shadow: 6px 6px 0 #2d3436, 10px 10px 20px rgba(0,0,0,0.5); animation: titleFloat 2s ease-in-out infinite; }
        @keyframes titleFloat { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-15px); } }
        .btn { padding: 20px 80px; font-size: 28px; background: #fdcb6e; color: #2d3436; border: none; cursor: pointer; border-radius: 60px; font-weight: 900; box-shadow: 0 10px 0 #e1b12c; transition: 0.1s; pointer-events: auto; text-transform: uppercase; letter-spacing: 2px; }
        .btn:hover { background: #ffe66d; }
        .btn:active { transform: translateY(6px); box-shadow: 0 4px 0 #e1b12c; }
    </style>
</head>
<body>
    <div id="ui-layer">
        <div id="timer">03:00</div>
        <div id="kill-log"></div>
        <div id="kill-feed"></div>
    </div>
    <div id="overlay">
        <h1 id="title">HEX-A-GONE</h1>
        <p style="margin-bottom: 40px; font-size: 20px; background: rgba(0,0,0,0.3); padding: 10px 20px; border-radius: 10px;">WASD: Move | SPACE: Jump | Left Click: SMASH!</p>
        <button id="start-btn" class="btn">JOIN QUEUE</button>
    </div>

    <script type="importmap">{ 
        "imports": { 
            "three": "https://unpkg.com/three@0.160.0/build/three.module.js",
            "three/addons/": "https://unpkg.com/three@0.160.0/examples/jsm/"
        } 
    }</script>

    <script type="module">
        import * as THREE from 'three';

        // --- Init Scene ---
        const scene = new THREE.Scene();
        // 背景グラデーション (本気作成のベース)
        scene.background = new THREE.Color(0x81ecec); 
        //scene.background = new THREE.Color(0xa29bfe); // Deepen the sky color
        
        // Fog (幻想的な霞)
        scene.fog = new THREE.Fog(0x81ecec, 60, 260); 

        const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 2000);
        const renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        renderer.shadowMap.enabled = true;
        document.body.appendChild(renderer.domElement);

        // Lighting (環境光を強めに、ディレクショナルライトを調整)
        const hemi = new THREE.HemisphereLight(0xffffff, 0x636e72, 1.8);
        scene.add(hemi);
        const sun = new THREE.DirectionalLight(0xffffff, 2.2);
        sun.position.set(60, 110, 60);
        sun.castShadow = true;
        sun.shadow.camera.left = -110; sun.shadow.camera.right = 110;
        sun.shadow.camera.top = 110; sun.shadow.camera.bottom = -110;
        sun.shadow.mapSize.width = 2048; sun.shadow.mapSize.height = 2048;
        scene.add(sun);

        // --- Effects System ---
        const particles = [];

        // --- Background Decor (本気作成のアセット) ---
        function addDecor() {
            const decorGroup = new THREE.Group();
            
            // 1. 低ポリゴンの雲 (数を増やし、形を多様に)
            const cloudMat = new THREE.MeshStandardMaterial({ color: 0xffffff, flatShading: true, transparent: true, opacity: 0.9 });
            for(let i=0; i<45; i++) {
                const geo = new THREE.IcosahedronGeometry(Math.random()*9 + 5, 1);
                const cloud = new THREE.Mesh(geo, cloudMat);
                const angle = Math.random() * Math.PI * 2;
                const dist = 160 + Math.random() * 220;
                cloud.position.set(Math.cos(angle)*dist, Math.random()*90 - 15, Math.sin(angle)*dist);
                cloud.rotation.y = Math.random() * Math.PI;
                decorGroup.add(cloud);
                // 微妙な動きを付与
                cloud.userData = { speed: Math.random() * 0.002, rotSpeed: Math.random() * 0.005 };
            }

            // 2. 浮遊島 (遠景、形を細かく)
            for(let i=0; i<12; i++) {
                const island = new THREE.Group();
                
                // 島の下部 ( Cone )
                const islandGeo = new THREE.ConeGeometry(Math.random()*5 + 12, 22, 6);
                islandGeo.rotateX(Math.PI);
                const islandMat = new THREE.MeshStandardMaterial({ color: 0x636e72, flatShading: true });
                const baseMesh = new THREE.Mesh(islandGeo, islandMat);
                island.add(baseMesh);

                // 島の上部 ( 草原/台地 )
                const topGeo = new THREE.CylinderGeometry(Math.random()*5 + 12, Math.random()*5 + 12, 3, 6);
                const topMat = new THREE.MeshStandardMaterial({ color: 0x55efc4, flatShading: true });
                const topMesh = new THREE.Mesh(topGeo, topMat);
                topMesh.position.y = 11;
                island.add(topMesh);

                // 装飾 (小さな木や岩、滝)
                if (Math.random() < 0.6) {
                    const treeGeo = new THREE.ConeGeometry(2, 5, 4);
                    const treeMat = new THREE.MeshStandardMaterial({ color: 0x00b894 });
                    const tree = new THREE.Mesh(treeGeo, treeMat);
                    tree.position.set(Math.random()*8 - 4, 14, Math.random()*8 - 4);
                    island.add(tree);
                }
                if (Math.random() < 0.3) { // 滝
                    const fallGeo = new THREE.CylinderGeometry(1, 1, 15, 3);
                    const fallMat = new THREE.MeshStandardMaterial({ color: 0x0984e3, transparent: true, opacity: 0.8 });
                    const fall = new THREE.Mesh(fallGeo, fallMat);
                    fall.position.set(Math.random()*10 - 5, 3, Math.random()*10 - 5);
                    island.add(fall);
                }

                const angle = (i / 12) * Math.PI * 2 + Math.random() * 0.5;
                const dist = 280 + Math.random() * 100;
                island.position.set(Math.cos(angle)*dist, Math.random()*40 - 20, Math.sin(angle)*dist);
                island.rotation.y = Math.random() * Math.PI;
                
                decorGroup.add(island);
                island.userData = { speed: Math.random() * 0.001, phase: Math.random() * Math.PI };
            }

            // 3. 巨大なクリスタル (発光)
            const cryMat = new THREE.MeshStandardMaterial({ color: 0xa29bfe, emissive: 0xa29bfe, emissiveIntensity: 0.6, flatShading: true, transparent: true, opacity: 0.8 });
            for(let i=0; i<6; i++) {
                const geo = new THREE.OctahedronGeometry(Math.random()*6 + 10, 0);
                const crystal = new THREE.Mesh(geo, cryMat);
                const angle = Math.random() * Math.PI * 2;
                const dist = 400;
                crystal.position.set(Math.cos(angle)*dist, 10 + Math.random()*60, Math.sin(angle)*dist);
                decorGroup.add(crystal);
                crystal.userData = { rotSpeed: 0.003 + Math.random()*0.002 };
            }

            // 4. 古代のアーチ (遠景)
            const archMat = new THREE.MeshStandardMaterial({ color: 0xd63031, flatShading: true });
            for(let i=0; i<4; i++) {
                const arch = new THREE.Group();
                const pillarGeo = new THREE.CylinderGeometry(3, 3, 40, 6);
                const pillar1 = new THREE.Mesh(pillarGeo, archMat);
                pillar1.position.x = -15;
                arch.add(pillar1);
                const pillar2 = new THREE.Mesh(pillarGeo, archMat);
                pillar2.position.x = 15;
                arch.add(pillar2);
                const topGeo = new THREE.BoxGeometry(40, 5, 5);
                const top = new THREE.Mesh(topGeo, archMat);
                top.position.y = 20;
                arch.add(top);

                const angle = (i / 4) * Math.PI * 2 + Math.PI/4;
                const dist = 350;
                arch.position.set(Math.cos(angle)*dist, -10, Math.sin(angle)*dist);
                arch.lookAt(0, -10, 0);
                decorGroup.add(arch);
            }

            // 5. 複雑な熱気球 (形を詳細に)
            const balloonColors = [0xff7675, 0x74b9ff, 0xa29bfe, 0xfbc531];
            for(let i=0; i<7; i++) {
                const balloon = new THREE.Group();
                
                // 気球部分 ( Sphere + Cone )
                const bGeo = new THREE.SphereGeometry(7, 10, 10);
                const bMat = new THREE.MeshStandardMaterial({ color: balloonColors[i % 4], flatShading: true });
                const bMesh = new THREE.Mesh(bGeo, bMat);
                balloon.add(bMesh);
                
                const bBottomGeo = new THREE.ConeGeometry(7, 8, 10);
                bBottomGeo.rotateX(Math.PI);
                const bBottomMesh = new THREE.Mesh(bBottomGeo, bMat);
                bBottomMesh.position.y = -6;
                balloon.add(bBottomMesh);

                // ゴンドラ ( Box )
                const gGeo = new THREE.BoxGeometry(3, 2, 3);
                const gMat = new THREE.MeshStandardMaterial({ color: 0x8b4513, flatShading: true });
                const gondola = new THREE.Mesh(gGeo, gMat);
                gondola.position.y = -14;
                balloon.add(gondola);

                // 紐 ( Cylinder )
                const ropeMat = new THREE.MeshStandardMaterial({ color: 0x000000 });
                for(let j=0; j<4; j++) {
                    const rGeo = new THREE.CylinderGeometry(0.1, 0.1, 8, 4);
                    const rope = new THREE.Mesh(rGeo, ropeMat);
                    const rAngle = (j/4) * Math.PI * 2;
                    rope.position.set(Math.cos(rAngle)*2.5, -10, Math.sin(rAngle)*2.5);
                    balloon.add(rope);
                }

                balloon.position.set(Math.random()*240 - 120, 35 + Math.random()*60, Math.random()*240 - 120);
                decorGroup.add(balloon);
                // 微妙な動きと回転を付与
                balloon.userData = { speed: 0.006 + Math.random()*0.012, phase: Math.random()*Math.PI*2, rotSpeed: (Math.random()-0.5) * 0.004 };
            }

            scene.add(decorGroup);
            return decorGroup;
        }
        const decor = addDecor();

        // --- World Constants ---
        const GRID_SIZE = 18; 
        const TILE_RADIUS = 0.9;
        const TILE_SPACING = 1.6;
        const LAYER_GAP = 14;
        const WATER_Y = -40;
        let gameState = 'START';
        let timeLeft = 180; 

        const ADDITIONAL_ELEMENTS = {
            WAVE_PARAMS: {
                min_amplitude: 0.8,
                max_amplitude: 3.5,
                min_speed: 1.2,
                max_speed: 2.5
            },
            DROWN_ANIM: {
                sink_speed: 0.02,
                rot_speed: 0.2,
                frantic_swing_speed: 12.0,
                frantic_swing_angle: Math.PI / 1.2
            }
        };

        // --- 海の作成 (水色でミニゲーム感を強調) ---
        const waterGeo = new THREE.PlaneGeometry(3000, 3000, 128, 128);
        const waterMat = new THREE.MeshStandardMaterial({ 
            color: 0x00d2ff, 
            transparent: true, 
            opacity: 0.75, 
            roughness: 0.1,
            metalness: 0.2,
            emissive: 0x0984e3,
            emissiveIntensity: 0.5
        });
        const water = new THREE.Mesh(waterGeo, waterMat);
        water.rotation.x = -Math.PI / 2;
        water.position.y = WATER_Y;
        water.receiveShadow = true;
        scene.add(water);

        const initialVertices = waterGeo.attributes.position.array.slice();

        const tiles = [];
        const tileGeo = new THREE.CylinderGeometry(TILE_RADIUS, TILE_RADIUS, 0.5, 6); 
        const colors = [0xfbc531, 0x0984e3, 0xd63031]; 

        function buildLayer(y, colorIdx) {
            for (let x = 0; x < GRID_SIZE; x++) {
                for (let z = 0; z < GRID_SIZE; z++) {
                    const mat = new THREE.MeshStandardMaterial({ 
                        color: colors[colorIdx], 
                        emissive: colors[colorIdx], 
                        emissiveIntensity: 0.2,
                        transparent: true,
                        opacity: 1.0,
                        flatShading: true // ミニゲーム感を出すためにフラットシェーディング
                    });
                    const tile = new THREE.Mesh(tileGeo, mat);
                    const xOff = (z % 2) * (TILE_SPACING * 0.5);
                    tile.position.set((x - GRID_SIZE/2) * TILE_SPACING + xOff, y, (z - GRID_SIZE/2) * (TILE_SPACING * 0.866));
                    tile.userData = { 
                        status: 'stable', 
                        timer: 0, 
                        initialPos: tile.position.clone(),
                        layer: colorIdx
                    };
                    tile.receiveShadow = true;
                    scene.add(tile);
                    tiles.push(tile);
                }
            }
        }
        [0, -LAYER_GAP, -LAYER_GAP*2].forEach((y, i) => buildLayer(y, i));

        function isPointInHex(px, pz, hx, hz, radius) {
            const r = radius * 1.1; 
            const dx = Math.abs(px - hx);
            const dz = Math.abs(pz - hz);
            return (dz <= r * Math.sqrt(3)/2) && (dz <= Math.sqrt(3) * (r - dx));
        }

        let camPhi = 0.5, camTheta = 0;
        window.addEventListener('mousemove', (e) => {
            if (document.pointerLockElement === document.body || e.buttons === 2) {
                camTheta -= e.movementX * 0.005;
                camPhi = Math.max(0.1, Math.min(1.4, camPhi + e.movementY * 0.005));
            }
        });
        let zoom = 18;
        window.addEventListener('wheel', e => zoom = Math.max(8, Math.min(50, zoom + e.deltaY * 0.01)));

        function genName() {
            const list = ["Pro_Gamer", "HexMaster", "Ninja", "Bot_99", "Shadow", "King", "ZOD", "Luffy", "Mario", "X_Dark_X"];
            return list[Math.floor(Math.random()*list.length)] + "_" + Math.floor(Math.random()*999);
        }

        class Agent {
            constructor(color, name, isPlayer = false) {
                this.name = name; this.isPlayer = isPlayer;
                this.alive = true; this.onGround = false;
                this.velocity = new THREE.Vector3();
                this.smoothedMove = new THREE.Vector3(); 
                this.hitTimer = 0; 
                this.kbCooldown = 0; 
                this.swingCooldown = 0; 
                this.drowning = false;
                this.drownTimer = 0;
                this.lastHitBy = null; 

                this.mesh = new THREE.Group();
                this.mat = new THREE.MeshStandardMaterial({ color, flatShading: true }); // キャラクターもフラットに
                const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.35, 0.5, 4, 8), this.mat);
                body.castShadow = true; body.position.y = 0.5;
                this.mesh.add(body);

                this.batPivot = new THREE.Group();
                this.batPivot.position.set(0.4, 0.5, 0);
                const bat = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.05, 1.1), new THREE.MeshStandardMaterial({color: 0x8b4513, flatShading: true}));
                bat.rotation.x = Math.PI/2; bat.position.z = 0.5;
                this.batPivot.add(bat);
                this.mesh.add(this.batPivot);

                this.swinging = false; this.swingTime = 0;
                this.mesh.position.set((Math.random()-0.5)*15, 5, (Math.random()-0.5)*15);
                scene.add(this.mesh);
            }

            swing() { 
                if(!this.swinging && this.swingCooldown <= 0) { 
                    this.swinging = true; 
                    this.swingTime = 0; 
                    this.swingCooldown = 65; 
                } 
            }

            update(keys) {
                if (!this.alive) return;
                if (this.swingCooldown > 0) this.swingCooldown--;

                if (this.drowning) {
                    this.drownTimer++;
                    this.mesh.position.y -= ADDITIONAL_ELEMENTS.DROWN_ANIM.sink_speed;
                    this.mesh.rotation.x += (Math.random() - 0.5) * ADDITIONAL_ELEMENTS.DROWN_ANIM.rot_speed;
                    this.mesh.rotation.z += (Math.random() - 0.5) * ADDITIONAL_ELEMENTS.DROWN_ANIM.rot_speed;
                    if (this.drownTimer > 60) this.eliminate();
                    return;
                }

                if (this.hitTimer > 0) {
                    this.hitTimer--;
                    this.mat.emissive.setHex(0xff0000);
                    this.mat.emissiveIntensity = 0.8;
                } else {
                    this.mat.emissiveIntensity = 0;
                }
                if (this.kbCooldown > 0) this.kbCooldown--;

                let moveVec = new THREE.Vector3();
                if (this.isPlayer) {
                    const forward = new THREE.Vector3(0,0,-1).applyAxisAngle(new THREE.Vector3(0,1,0), camTheta);
                    const right = new THREE.Vector3(1,0,0).applyAxisAngle(new THREE.Vector3(0,1,0), camTheta);
                    if (keys['KeyW']) moveVec.add(forward);
                    if (keys['KeyS']) moveVec.sub(forward);
                    if (keys['KeyA']) moveVec.sub(right);
                    if (keys['KeyD']) moveVec.add(right);
                    if (keys['Space'] && this.onGround) {
                        this.velocity.y = 0.28;
                        this.onGround = false;
                    }
                } else {
                    // --- CPU Behavior logic (Weakened & Fighting) ---
                    const myPos = this.mesh.position;
                    const substeps = 4;
                    
                    // CPU弱体化パラメータ
                    const cpuMoveSpeed = 0.10; // プレイヤーより遅く (0.13 -> 0.10)
                    const cpuTilePanicTimer = 20; // 落下中タイルへの反応を遅く (15 -> 20)
                    const cpuJumpChance = 0.005; // ジャンプ頻度を下げる (0.01 -> 0.005)

                    // 1. 周囲の敵（プレイヤー含む）を検知
                    const enemies = agents.filter(a => a.alive && a !== this && Math.abs(a.mesh.position.y - myPos.y) < 2);
                    const target = enemies.sort((a,b) => a.mesh.position.distanceTo(myPos) - b.mesh.position.distanceTo(myPos))[0];

                    if (target) {
                        // 2. 敵に向かって移動する (戦わせる)
                        moveVec.subVectors(target.mesh.position, myPos);
                        
                        // 3. バットを振る (間合いに入ったら確実に攻撃)
                        if (target.mesh.position.distanceTo(myPos) < cpuBatRange) {
                            this.swing();
                        }
                    } else {
                        // 4. 敵がいない場合は中央に向かう、またはランダムに移動 (弱体化：落ちやすく)
                        if (Math.random() < 0.2) {
                             const toCenter = new THREE.Vector3().subVectors(new THREE.Vector3(0, myPos.y, 0), myPos);
                             if (toCenter.length() > 0.5) moveVec.add(toCenter.multiplyScalar(0.3));
                        } else {
                            // ランダムな方向へ (落ちやすく)
                            moveVec.set(Math.random()-0.5, 0, Math.random()-0.5).normalize().multiplyScalar(0.5);
                        }
                    }

                    // 5. 落下回避ロジックを弱体化 (落ちやすく)
                    const currentTile = tiles.find(t => t.visible && isPointInHex(myPos.x, myPos.z, t.position.x, t.position.z, TILE_RADIUS) && Math.abs(myPos.y - t.position.y) < 1);
                    if (currentTile) {
                        // 反応を遅くする (cpuTilePanicTimer)
                        if (currentTile.userData.status === 'triggered' && currentTile.userData.timer > cpuTilePanicTimer) {
                            const safeTiles = tiles.filter(t => t.visible && t.userData.status === 'stable' && Math.abs(t.position.y - currentTile.position.y) < 1);
                            if (safeTiles.length > 0) {
                                // 落下回避の方向計算をわずかに不正確に
                                const nearestSafe = safeTiles.sort((a,b) => a.position.distanceTo(myPos) - b.position.distanceTo(myPos))[0];
                                const escapeVec = new THREE.Vector3().subVectors(nearestSafe.position, myPos);
                                moveVec.lerp(escapeVec, 0.6); // 完全にエスケープしない
                            }
                        } 
                    }

                    // 6. ジャンプ頻度を下げる (cpuJumpChance)
                    if (Math.random() < cpuJumpChance && this.onGround) this.velocity.y = 0.25;

                    // CPU速度調整 ( cpuMoveSpeed )
                    if (moveVec.length() > 0) moveVec.y = 0, moveVec.normalize().multiplyScalar(cpuMoveSpeed);
                }

                // プレイヤーの速度 ( 変わらず )
                if (this.isPlayer && moveVec.length() > 0) moveVec.y = 0, moveVec.normalize().multiplyScalar(0.13);

                this.smoothedMove.lerp(moveVec, this.isPlayer ? 1.0 : 0.2); 
                if (this.smoothedMove.length() > 0.01) {
                    this.mesh.position.add(this.smoothedMove);
                    this.mesh.rotation.y = THREE.MathUtils.lerp(this.mesh.rotation.y, Math.atan2(this.smoothedMove.x, this.smoothedMove.z), 0.15);
                }

                const substeps = 4;
                for(let s=0; s<substeps; s++) {
                    this.velocity.y -= 0.01 / substeps;
                    this.mesh.position.y += this.velocity.y / substeps;
                    this.mesh.position.x += this.velocity.x / substeps;
                    this.mesh.position.z += this.velocity.z / substeps;
                    this.velocity.x *= Math.pow(0.92, 1/substeps);
                    this.velocity.z *= Math.pow(0.92, 1/substeps);

                    let groundedThisStep = false;
                    for(const t of tiles) {
                        if(!t.visible) continue;
                        const inHex = isPointInHex(this.mesh.position.x, this.mesh.position.z, t.position.x, t.position.z, TILE_RADIUS);
                        const dy = this.mesh.position.y - t.position.y;
                        if(inHex && dy > 0 && dy < 0.6 && this.velocity.y <= 0) {
                            this.mesh.position.y = t.position.y + 0.45;
                            this.velocity.y = 0; groundedThisStep = true;
                            if(t.userData.status === 'stable') t.userData.status = 'triggered';
                            break;
                        }
                    }
                    this.onGround = groundedThisStep;
                }

                if (this.swinging) {
                    this.swingTime += 0.15; 
                    this.batPivot.rotation.y = Math.sin(this.swingTime * 1.5) * 2.5; 
                    if(this.swingTime > 1.0 && this.swingTime < 1.4) {
                        agents.forEach(a => {
                            if(a !== this && a.alive && a.kbCooldown <= 0) {
                                if(a.mesh.position.distanceTo(this.mesh.position) < agentBatRange) {
                                    const push = new THREE.Vector3().subVectors(a.mesh.position, this.mesh.position).normalize().multiplyScalar(0.6);
                                    a.velocity.x = push.x; a.velocity.z = push.z;
                                    a.velocity.y = 0.2; a.hitTimer = 15; a.kbCooldown = 20; 
                                    a.lastHitBy = this.name; 
                                }
                            }
                        });
                    }
                    if(this.swingTime > Math.PI) { this.swinging = false; this.batPivot.rotation.y = 0; }
                }

                if (this.mesh.position.y < WATER_Y + 1 && !this.drowning) {
                    this.drowning = true; this.velocity.set(0,0,0);
                }
            }

            eliminate() {
                if(!this.alive) return;
                this.alive = false; this.mesh.visible = false;
                addLog(`${this.name} fell!`);
                
                if (this.lastHitBy === "YOU") {
                    addKillLog(this.name);
                }
            }
        }

        const agents = [new Agent(0xf78fb3, "YOU", true)];
        for(let i=0; i<14; i++) agents.push(new Agent(Math.random()*0xffffff, genName()));

        const keys = {};
        window.onkeydown = e => keys[e.code] = true;
        window.onkeyup = e => keys[e.code] = false;
        window.onmousedown = (e) => { if(e.button === 0 && gameState === 'PLAYING') agents[0].swing(); };

        function addLog(m) {
            const l = document.createElement('div'); l.className = 'log'; l.innerText = m;
            document.getElementById('kill-log').appendChild(l);
            setTimeout(() => l.remove(), 3000);
        }

        function addKillLog(victimName) {
            const feed = document.getElementById('kill-feed');
            const msg = document.createElement('div');
            msg.className = 'kill-msg';
            msg.innerText = `YOU KILLED ${victimName}`;
            feed.appendChild(msg);
            setTimeout(() => msg.remove(), 4200); // 表示時間をわずかに伸ばす
        }

        document.getElementById('start-btn').onclick = () => {
            gameState = 'PLAYING'; document.getElementById('overlay').style.display = 'none';
            document.body.requestPointerLock();
        };

        // バットの間合い (agent:プレイヤー用, cpuBatRange:CPU用)
        const agentBatRange = 2.5; 
        const cpuBatRange = 2.2; 

        function animate() {
            requestAnimationFrame(animate);
            const time = Date.now() * 0.001;

            // --- 背景アニメーション (本気作成のアセットに動きを) ---
            decor.children.forEach(child => {
                // 1. 雲の動き
                if(child.geometry instanceof THREE.IcosahedronGeometry) {
                    child.position.y += Math.sin(time * 0.5 + child.position.x) * 0.01;
                    child.rotation.y += child.userData.rotSpeed;
                }
                // 2. 浮遊島の動き
                if(child instanceof THREE.Group && child.userData.phase) {
                    child.position.y += Math.sin(time + child.userData.phase) * 0.03;
                    child.rotation.y += child.userData.speed;
                }
                // 3. クリスタルの回転
                if(child.geometry instanceof THREE.OctahedronGeometry) {
                    child.rotation.y += child.userData.rotSpeed;
                    child.rotation.z += child.userData.rotSpeed * 0.5;
                }
                // 5. 熱気球の動き
                if(child instanceof THREE.Group && child.userData.speed) {
                    child.position.y += Math.sin(time * 0.8 + child.userData.phase) * 0.03;
                    child.rotation.y += child.userData.rotSpeed;
                    child.rotation.z += Math.sin(time * 0.5) * 0.01; // 微妙に揺れる
                }
            });

            // 海のダイナミック波
            const posAttr = waterGeo.attributes.position;
            const progress = 1 - (timeLeft / 180); 
            const amp = ADDITIONAL_ELEMENTS.WAVE_PARAMS.min_amplitude + progress * (ADDITIONAL_ELEMENTS.WAVE_PARAMS.max_amplitude - ADDITIONAL_ELEMENTS.WAVE_PARAMS.min_amplitude);
            const speed = ADDITIONAL_ELEMENTS.WAVE_PARAMS.min_speed + progress * (ADDITIONAL_ELEMENTS.WAVE_PARAMS.max_speed - ADDITIONAL_ELEMENTS.WAVE_PARAMS.min_speed);

            for (let i = 0; i < posAttr.count; i++) {
                const x = initialVertices[i * 3], y = initialVertices[i * 3 + 1];
                const wave = Math.sin(x * 0.04 + time * speed) * amp + Math.cos(y * 0.04 + time * speed) * amp;
                posAttr.setZ(i, wave);
            }
            posAttr.needsUpdate = true;

            if (gameState === 'PLAYING') {
                timeLeft -= 1/60;
                const m = Math.max(0, Math.floor(timeLeft/60)), s = Math.max(0, Math.floor(timeLeft%60));
                document.getElementById('timer').innerText = `${m}:${s<10?'0'+s:s}`;

                for (let i = tiles.length - 1; i >= 0; i--) {
                    const t = tiles[i];
                    if (t.userData.status === 'triggered') {
                        t.userData.timer++;
                        const p = t.userData.timer;
                        if (p < 45) {
                            const shake = p * 0.004;
                            t.position.x = t.userData.initialPos.x + (Math.random()-0.5) * shake;
                            t.material.emissiveIntensity = p / 15;
                            t.material.color.lerp(new THREE.Color(0xff7675), 0.05);
                        } else {
                            t.position.y -= 0.18;
                            t.rotation.x += 0.03;
                            const fade = Math.max(0, 1 - (p - 45) / 270);
                            t.material.opacity = fade;
                            if (fade <= 0 || t.position.y < -150) {
                                t.visible = false; scene.remove(t); tiles.splice(i, 1);
                                t.geometry.dispose(); t.material.dispose();
                            }
                        }
                    }
                }

                agents.forEach(a => a.update(keys));
                const alive = agents.filter(a => a.alive);
                if((alive.length === 1 && agents[0].alive) || (alive.length === 0) || timeLeft <= 0) {
                    gameState = 'END'; document.exitPointerLock();
                    document.getElementById('overlay').style.display = 'flex';
                    const winner = alive[0] ? alive[0].name : "NO ONE";
                    document.getElementById('title').innerText = winner + " WINS!";
                    document.getElementById('start-btn').innerText = "REMATCH";
                    document.getElementById('start-btn').onclick = () => location.reload();
                }

                const target = (agents[0].alive) ? agents[0] : (alive[0] || agents[0]);
                const camX = target.mesh.position.x + zoom * Math.sin(camTheta) * Math.cos(camPhi);
                const camY = target.mesh.position.y + zoom * Math.sin(camPhi);
                const camZ = target.mesh.position.z + zoom * Math.cos(camTheta) * Math.cos(camPhi);
                camera.position.lerp(new THREE.Vector3(camX, camY, camZ), 0.12);
                camera.lookAt(target.mesh.position.clone().add(new THREE.Vector3(0, 1, 0)));
            }
            renderer.render(scene, camera);
        }
        animate();

        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight; camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });
    </script>
</body>
</html>
