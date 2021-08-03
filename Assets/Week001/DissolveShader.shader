Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        uIntensity ("intensity", Range(0,1) ) = 0

        [HDR]uColor ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 pos:POSITION;
                float2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float4 pos:POSITION;
                float2 uv:TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float uIntensity;

            float4 uColor;

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.pos);
                o.uv = v.uv;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float dissove = 1 - tex2D(_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw ).r;
                dissove = step(dissove, uIntensity);

                float4 color = float4(uColor.r, uColor.g, uColor.b, dissove);

                if(color.a < 0.1) discard;

                return color;
            }


            ENDCG
        }
    }
}
