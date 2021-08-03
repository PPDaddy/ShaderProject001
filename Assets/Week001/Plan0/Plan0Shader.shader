Shader "Custom/Plan0Shader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        uSlant("uSlant", Range(0, 1)) = 0.5
        [HDR]uEmissionColor("EmissionColor", Color) = (1, 1, 1, 1)
        uMaskTex("uMaskTex", 2D) = "white"{}
        uEmitTex("uEmitTex", 2D) = "white"{}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM

        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float uSlant;

        sampler2D uMaskTex;
        float4 uMaskTex_ST;

        float4 uEmissionColor;
        sampler2D uEmitTex;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)


        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;

            float2 uv = float2(1 - IN.uv_MainTex.x, IN.uv_MainTex.y);

            float mask = tex2D(uMaskTex, IN.uv_MainTex * uMaskTex_ST.xy + uMaskTex_ST.zw).r;
            float slantUV = step((uv.x + uv.y + (1 - mask)) / 5, uSlant);//MainTex MASK
            
            float emissionUV = smoothstep(uSlant, uSlant + 0.1, (uv.x + uv.y + mask) / 3);//Emission MASK
            if (slantUV < 0.1) discard;

            float emitMask = clamp(tex2D(uEmitTex, IN.uv_MainTex).r * (1 - uSlant), 0, 1);

            o.Albedo = lerp(c + (uEmissionColor * emitMask), uEmissionColor, emissionUV);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
