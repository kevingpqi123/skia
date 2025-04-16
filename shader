skia:
## 三角形
### Miter、Bevel
#version 400

uniform vec4 sk_RTAdjust;
in vec2 inPosition;
in vec4 inColor;
in float inCoverage;
noperspective out vec4 vcolor_S0;
void main() {
    vec4 color = inColor;
    color = color * inCoverage;
    vcolor_S0 = color;
    vec2 _tmp_1_inPosition = inPosition;
    gl_Position = vec4(_tmp_1_inPosition, 0.0, 1.0);
    gl_Position = vec4(gl_Position.xy * sk_RTAdjust.xz + gl_Position.ww * sk_RTAdjust.yw, 0.0, gl_Position.w);
}

#version 400

out vec4 sk_FragColor;
noperspective in vec4 vcolor_S0;
void main() {
    vec4 outputColor_S0 = vcolor_S0;
    {
        sk_FragColor = outputColor_S0;
    }
}

### Round、Miter-dash
#version 400

uniform vec4 sk_RTAdjust;
uniform vec2 uatlas_adjust_S0;
in vec4 fillBounds;
in vec4 color;
in vec4 locations;
noperspective out vec2 vatlasCoord_S0;
flat out vec4 vcolor_S0;
void main() {
    vec2 unitCoord = vec2(float(gl_VertexID & 1), float(gl_VertexID >> 1));
    vec2 devCoord = mix(fillBounds.xy, fillBounds.zw, unitCoord);
    vec2 atlasTopLeft = vec2(abs(locations.x) - 1.0, locations.y);
    vec2 devTopLeft = locations.zw;
    bool transposed = locations.x < 0.0;
    vec2 atlasCoord = devCoord - devTopLeft;
    if (transposed) {
        atlasCoord = atlasCoord.yx;
    }
    atlasCoord += atlasTopLeft;
    vatlasCoord_S0 = atlasCoord * uatlas_adjust_S0;
    vcolor_S0 = color;
    gl_Position = vec4(devCoord, 0.0, 1.0);
    gl_Position = vec4(gl_Position.xy * sk_RTAdjust.xz + gl_Position.ww * sk_RTAdjust.yw, 0.0, gl_Position.w);
}


#version 400

out vec4 sk_FragColor;
uniform sampler2D uTextureSampler_0_S0;
noperspective in vec2 vatlasCoord_S0;
flat in vec4 vcolor_S0;
void main() {
    vec4 outputCoverage_S0 = vec4(1.0);
    float atlasCoverage = texture(uTextureSampler_0_S0, vatlasCoord_S0, -0.475).x;
    outputCoverage_S0 *= atlasCoverage;
    vec4 outputColor_S0 = vcolor_S0;
    {
        sk_FragColor = outputColor_S0 * outputCoverage_S0;
    }
}



### Miter_Join:

#version 400

uniform vec4 sk_RTAdjust;
in vec2 inPosition;
void main() {
    vec2 _tmp_1_inPosition = inPosition;
    gl_Position = vec4(_tmp_1_inPosition, 0.0, 1.0);
    gl_Position = vec4(gl_Position.xy * sk_RTAdjust.xz + gl_Position.ww * sk_RTAdjust.yw, 0.0, gl_Position.w);
}


#version 400

out vec4 sk_FragColor;
uniform vec4 uColor_S0;
void main() {
    vec4 outputColor_S0 = uColor_S0;
    {
        sk_FragColor = outputColor_S0;
    }
}


### Round_Join:
## 片段着色器
#version 400

out vec4 sk_FragColor;
uniform vec4 ucolor_S0;
void main() {
    vec4 outputColor_S0 = ucolor_S0;
    {
        sk_FragColor = outputColor_S0;
    }
}


## 顶点着色器
#version 400

const float PI = 3.14159274;
const float PRECISION = 4.0;
const float NUM_TOTAL_EDGES = 16383.0;
uniform vec4 sk_RTAdjust; // 调整屏幕坐标
uniform vec3 utessControlArgs_S0; // 控制镶嵌参数，如每弧度的分段数、描边半径
uniform vec4 uaffineMatrix_S0; // uaffineMatrix_S0、utranslate_S0 用于将路径坐标转换为设备坐标
uniform vec2 utranslate_S0;
in vec4 pts01Attr;  // pts01Attr、pts23Attr 是路径的控制点坐标
in vec4 pts23Attr;
in vec2 argsAttr;  // argsAttr 是上一个控制点坐标
// 计算两个点之间的归一化向量，处理零向量的特殊情况
vec2 robust_normalize_diff_f2f2f2(vec2 a, vec2 b) {
    vec2 diff = a - b;
    if (diff == vec2(0.0)) {
        return vec2(0.0);
    } else {
        float invMag = 1.0 / max(abs(diff.x), abs(diff.y));
        return normalize(invMag * diff);
    }
}
// 计算两个点之间的线性插值
vec2 unchecked_mix_f2f2f2f(vec2 a, vec2 b, float T) {
    return fma(b - a, vec2(T), a);
}
// 计算贝塞尔曲线的最大二阶差分，用于确定细分段数
float wangs_formula_max_fdiff_p2_ff2f2f2f2f22(vec2 p0, vec2 p1, vec2 p2, vec2 p3, mat2 matrix) {
    vec2 d0 = matrix * (fma(vec2(-2.0), p1, p2) + p0);
    vec2 d1 = matrix * (fma(vec2(-2.0), p2, p3) + p1);
    return max(dot(d0, d0), dot(d1, d1));
}
// 计算圆锥曲线的参数化公式，用于确定细分段数
float wangs_formula_conic_p2_fff2f2f2f(float _precision_, vec2 p0, vec2 p1, vec2 p2, float w) {
    vec2 C = (min(min(p0, p1), p2) + max(max(p0, p1), p2)) * 0.5;
    p0 -= C;
    p1 -= C;
    p2 -= C;
    float m = sqrt(max(max(dot(p0, p0), dot(p1, p1)), dot(p2, p2)));
    vec2 dp = fma(vec2(-2.0 * w), p1, p0) + p2;
    float dw = abs(fma(-2.0, w, 2.0));
    float rp_minus_1 = max(0.0, fma(m, _precision_, -1.0));
    float numer = length(dp) * _precision_ + rp_minus_1 * dw;
    float denom = 4.0 * min(w, 1.0);
    return numer / denom;
}
void main() {
    float NUM_RADIAL_SEGMENTS_PER_RADIAN = utessControlArgs_S0.x; // 每弧度的径向细分段数
    float STROKE_RADIUS = utessControlArgs_S0.z;  // 描边半径
    mat2 AFFINE_MATRIX = mat2(uaffineMatrix_S0.xy, uaffineMatrix_S0.zw);  // 仿射变换矩阵
    vec2 TRANSLATE = utranslate_S0;  // 平移向量
    vec2 p0 = pts01Attr.xy; // 控制点坐标
    vec2 p1 = pts01Attr.zw;
    vec2 p2 = pts23Attr.xy;
    vec2 p3 = pts23Attr.zw;
    vec2 lastControlPoint = argsAttr;  // 上一个控制点坐标,用于计算切线
    float w = -1.0;  // 圆锥曲线的权重
    // 判断曲线类型，处理圆锥曲线
    if (isinf(pts23Attr.w)) {
        w = p3.x;
        p3 = p2;
    }
    // 计算细分段数
    float numParametricSegments;
    if (w < 0.0) {
        // 处理贝塞尔曲线
        if (p0 == p1 && p2 == p3) {
            numParametricSegments = 1.0;
        } else {
            float _0_m = wangs_formula_max_fdiff_p2_ff2f2f2f2f22(p0, p1, p2, p3, AFFINE_MATRIX);
            numParametricSegments = max(ceil(sqrt(3.0 * sqrt(_0_m))), 1.0);
        }
    } else {
        // 处理圆锥曲线
        float _1_n2 = wangs_formula_conic_p2_fff2f2f2f(PRECISION, AFFINE_MATRIX * p0, AFFINE_MATRIX * p1, AFFINE_MATRIX * p2, w);
        numParametricSegments = max(ceil(sqrt(_1_n2)), 1.0);
    }
    // 计算切线, 计算起始点和结束点的切线
    vec2 tan0 = robust_normalize_diff_f2f2f2(p0 == p1 ? (p1 == p2 ? p3 : p2) : p1, p0);
    vec2 tan1 = robust_normalize_diff_f2f2f2(p3, p3 == p2 ? (p2 == p1 ? p0 : p1) : p2);
    if (tan0 == vec2(0.0)) {
        tan0 = vec2(1.0, 0.0);
        tan1 = vec2(-1.0, 0.0);
    }
    float edgeID = float(gl_VertexID >> 1);
    if ((gl_VertexID & 1) != 0) {
        edgeID = -edgeID;
    }
    // 计算连接点的切线
    vec2 prevTan = robust_normalize_diff_f2f2f2(p0, lastControlPoint);
    // 计算连接点的旋转角度
    float joinRads = acos(clamp(dot(prevTan, tan0), -1.0, 1.0));
    // 根据旋转角度和每弧度的细分段数计算连接点的细分段数
    float numRadialSegmentsInJoin = max(ceil(joinRads * NUM_RADIAL_SEGMENTS_PER_RADIAN), 1.0);
    float numEdgesInJoin = numRadialSegmentsInJoin + 2.0;
    numEdgesInJoin = min(numEdgesInJoin, 16381.0);
    // 处理描边几何
    float turn = determinant(mat2(p2 - p0, p3 - p1)); // 计算切线的叉积，确定曲线的转向（顺时针或逆时针）
    float combinedEdgeID = abs(edgeID) - numEdgesInJoin;
    if (combinedEdgeID < 0.0) {
        tan1 = tan0;
        if (lastControlPoint != p0) {
            tan0 = robust_normalize_diff_f2f2f2(p0, lastControlPoint);
        }
        turn = determinant(mat2(tan0, tan1));
    }
    float cosTheta = clamp(dot(tan0, tan1), -1.0, 1.0);
    float rotation = acos(cosTheta);
    if (turn < 0.0) {
        rotation = -rotation;
    }
    float numRadialSegments;
    float strokeOutset = sign(edgeID);
    if (combinedEdgeID < 0.0) {
        numRadialSegments = numEdgesInJoin - 2.0;
        numParametricSegments = 1.0;
        p3 = (p2 = (p1 = p0));
        combinedEdgeID += numRadialSegments + 1.0;
        float sinEpsilon = 0.01;
        bool tangentsNearlyParallel = abs(turn) * inversesqrt(dot(tan0, tan0) * dot(tan1, tan1)) < sinEpsilon;
        if (!tangentsNearlyParallel || dot(tan0, tan1) < 0.0) {
            if (combinedEdgeID >= 0.0) {
                strokeOutset = turn < 0.0 ? min(strokeOutset, 0.0) : max(strokeOutset, 0.0);
            }
        }
        combinedEdgeID = max(combinedEdgeID, 0.0);
    } else {
        float maxCombinedSegments = (NUM_TOTAL_EDGES - numEdgesInJoin) - 1.0;
        numRadialSegments = max(ceil(abs(rotation) * NUM_RADIAL_SEGMENTS_PER_RADIAN), 1.0);
        numRadialSegments = min(numRadialSegments, maxCombinedSegments);
        numParametricSegments = min(numParametricSegments, (maxCombinedSegments - numRadialSegments) + 1.0);
    }
    float radsPerSegment = rotation / numRadialSegments;
    float numCombinedSegments = (numParametricSegments + numRadialSegments) - 1.0;
    bool isFinalEdge = combinedEdgeID >= numCombinedSegments;
    if (combinedEdgeID > numCombinedSegments) {
        strokeOutset = 0.0;
    }
    // 计算描边坐标
    vec2 tangent;
    vec2 strokeCoord;
    if (combinedEdgeID != 0.0 && !isFinalEdge) {
        // 计算插值点和切线
        vec2 A;
        vec2 B;
        vec2 C = p1 - p0;
        vec2 D = p3 - p0;
        if (w >= 0.0) {
            C *= w;
            B = 0.5 * D - C;
            A = (w - 1.0) * D;
            p1 *= w;
        } else {
            vec2 E = p2 - p1;
            B = E - C;
            A = fma(vec2(-3.0), E, D);
        }
        vec2 B_ = B * (numParametricSegments * 2.0);
        vec2 C_ = C * (numParametricSegments * numParametricSegments);
        float lastParametricEdgeID = 0.0;
        float maxParametricEdgeID = min(numParametricSegments - 1.0, combinedEdgeID);
        float negAbsRadsPerSegment = -abs(radsPerSegment);
        float maxRotation0 = (1.0 + combinedEdgeID) * abs(radsPerSegment);
        for (int _0_exp = 4;_0_exp >= 0; --_0_exp) {
            float testParametricID = lastParametricEdgeID + exp2(float(_0_exp));
            if (testParametricID <= maxParametricEdgeID) {
                vec2 testTan = fma(vec2(testParametricID), A, B_);
                testTan = fma(vec2(testParametricID), testTan, C_);
                float cosRotation = dot(normalize(testTan), tan0);
                float maxRotation = fma(testParametricID, negAbsRadsPerSegment, maxRotation0);
                maxRotation = min(maxRotation, PI);
                if (cosRotation >= cos(maxRotation)) {
                    lastParametricEdgeID = testParametricID;
                }
            }
        }
        float parametricT = lastParametricEdgeID / numParametricSegments;
        float lastRadialEdgeID = combinedEdgeID - lastParametricEdgeID;
        float angle0 = acos(clamp(tan0.x, -1.0, 1.0));
        angle0 = tan0.y >= 0.0 ? angle0 : -angle0;
        float radialAngle = fma(lastRadialEdgeID, radsPerSegment, angle0);
        tangent = vec2(cos(radialAngle), sin(radialAngle));
        vec2 norm = vec2(-tangent.y, tangent.x);
        float a = dot(norm, A);
        float b_over_2 = dot(norm, B);
        float c = dot(norm, C);
        float discr_over_4 = max(b_over_2 * b_over_2 - a * c, 0.0);
        float q = sqrt(discr_over_4);
        if (b_over_2 > 0.0) {
            q = -q;
        }
        q -= b_over_2;
        float _5qa = (-0.5 * q) * a;
        vec2 root = abs(fma(q, q, _5qa)) < abs(fma(a, c, _5qa)) ? vec2(q, a) : vec2(c, q);
        float radialT = root.y != 0.0 ? root.x / root.y : 0.0;
        radialT = clamp(radialT, 0.0, 1.0);
        if (lastRadialEdgeID == 0.0) {
            radialT = 0.0;
        }
        float T = max(parametricT, radialT);
        vec2 ab = unchecked_mix_f2f2f2f(p0, p1, T);
        vec2 bc = unchecked_mix_f2f2f2f(p1, p2, T);
        vec2 cd = unchecked_mix_f2f2f2f(p2, p3, T);
        vec2 abc = unchecked_mix_f2f2f2f(ab, bc, T);
        vec2 bcd = unchecked_mix_f2f2f2f(bc, cd, T);
        vec2 abcd = unchecked_mix_f2f2f2f(abc, bcd, T);
        float u = fma(w - 1.0, T, 1.0);
        float v = (w + 1.0) - u;
        float uv = fma(v - u, T, u);
        if (T != radialT) {
            tangent = w >= 0.0 ? robust_normalize_diff_f2f2f2(bc * u, ab * v) : robust_normalize_diff_f2f2f2(bcd, abc);
        }
        strokeCoord = w >= 0.0 ? abc / uv : abcd;
    } else {
        tangent = combinedEdgeID == 0.0 ? tan0 : tan1;
        strokeCoord = combinedEdgeID == 0.0 ? p0 : p3;
    }
    // 应用描边半径
    vec2 ortho = vec2(tangent.y, -tangent.x); // 计算法线方向
    strokeCoord += ortho * (STROKE_RADIUS * strokeOutset); // 根据描边半径和发现方向调整描边坐标
    vec2 devCoord = AFFINE_MATRIX * strokeCoord + TRANSLATE;
    gl_Position = vec4(devCoord, 0.0, 1.0);
    gl_Position = vec4(gl_Position.xy * sk_RTAdjust.xz + gl_Position.ww * sk_RTAdjust.yw, 0.0, gl_Position.w);
}



### Bevel_Join:





tgfx:
Vertex shader:

#version 150

precision mediump float;
uniform vec4 tgfx_RTAdjust;
uniform mat3 Matrix_P0;

in vec2 aPosition;
in float inCoverage;

out float Coverage_P0;

void main() {
    // Processor0 : DefaultGeometryProcessor
    vec2 position = (Matrix_P0 * vec3(aPosition, 1.0)).xy;
    Coverage_P0 = inCoverage;
    gl_Position = vec4(position.xy * tgfx_RTAdjust.xz + tgfx_RTAdjust.yw, 0, 1);
}



Fragment shader:

#version 150

precision mediump float;
uniform vec4 Color_P0;

in highp float Coverage_P0;

out vec4 tgfx_FragColor;

void main() {
    vec4 outputColor_P0;
    vec4 outputCoverage_P0;
    { // Processor0 : DefaultGeometryProcessor
        outputCoverage_P0 = vec4(Coverage_P0);
        outputColor_P0 = Color_P0;
    }
    { // Processor1 : EmptyXferProcessor
        tgfx_FragColor = outputColor_P0 * outputCoverage_P0;
    }
}


