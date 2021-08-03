Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        uNoiseTex ("Texture", 2D) = "white" {}


        uIntensity ("intensity", Range(0,1) ) = 0


        [HDR]uColorEdge ("uColorEdge", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off

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

            sampler2D uNoiseTex;
            float4 uNoiseTex_ST;

            float uIntensity;

            float4 uColorEdge;

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.pos);
                o.uv = v.uv;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 mainTex = tex2D(_MainTex, i.uv);
                float noiseTex = tex2D(uNoiseTex, i.uv * uNoiseTex_ST.xy + uNoiseTex_ST.zw ).r;

                //uIntensity = _SinTime.x;

                float dissove     = step(noiseTex, uIntensity);
                float dissoveEdge = step(noiseTex, uIntensity + 0.01);

                float4 color = lerp(mainTex, uColorEdge, dissoveEdge - dissove );
                color.a = dissoveEdge;

                if(color.a < 0.1) discard;

                return color;
            }
            ENDCG
        }
    }
}
