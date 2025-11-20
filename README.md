#Medieval Hexagon

## Shader
Pour le shader du ciel: https://www.youtube.com/watch?app=desktop&v=bR0v-yoZYZA

## Styles
4 Styles graphiques:

| |Biome|Saison|Musique associée|Vibe|titre|
|---|---|---|---|---|---|
|🌿 |Forêt tempérée / Prairie|printemps|Folk médiéval léger|Aventurier, lumineux| whispering-leaves |
|🏔️ |Montagne alpine / Taïga|été|Celtique / nordic ambient|Majestueux, froid| frozen-heights |
|🍂 |Steppe / Savane|Automne|Tribal / desert folk|Chaud, sec, nomade| winds-of-the-amber-steppe |
|❄️ |Toundra / Arctique|Hivers|Ambient glacial|Silencieux, mystique, cristallin| glacial-hush |

On pourrait structurer un système de biomes hexagonaux avec :
- Un paramètre elevation
- Un paramètre temperature
- Un paramètre humidity

Exemple simple (type Civilization ou Age of Wonders) :
- Temp élevée + humide → Vert
- Temp basse + moyenne altitude → Gris
- Temp élevée + sèche → Orange
- Temp très basse → Blanc
