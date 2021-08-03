Shader "Custom/VertexShader"
{
    Properties
    {
        uIntensity("uIntensity", Range(0,1)) = 0.5
        uAlbTex("uAlbTex", 2D) = "white"{}
        uNorTex("uNorTex", 2D) = "white"{}
        uMetRou("uMetRou", 2D) = "white"{}
        uEmitTex("uEmitTex", 2D) = "white"{}
        [HDR]uEmitColor("uEmitColor", Color) = (1,1,1,1)
        uMaskTex("uMaskTex", 2D) = "white"{}
        uAlbTex2("uAlbTex2", 2D) = "white"{}
    }

	SubShader
    {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow
		#pragma target 3.0

		struct Input
        {
			float4 vertColor;
            float2 uv_MainTex;
		};

        //UNIFORM----------
        float uIntensity;
        sampler2D uAlbTex;
        sampler2D uNorTex;
        sampler2D uMetRou;
        sampler2D uEmitTex;
        float4 uEmitColor;
        sampler2D uMaskTex;
        float4 uMaskTex_ST;
        sampler2D uAlbTex2;
        //-----------------

        float4 RotateAroundZInDegrees (float4 vertex, float degrees)
        {
            float alpha = degrees * UNITY_PI / 180.0;
            float sina, cosa;
            sincos(alpha, sina, cosa);
            float2x2 m = float2x2(cosa, -sina, sina, cosa);
            return float4(mul(m, vertex.xz), vertex.yw).xzyw;
        }

		void vert(inout appdata_full v, out Input o)
        {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.vertColor = v.color;

            float4 pos = RotateAroundZInDegrees(v.vertex * v.color.g, uIntensity * 270.0);
            pos +=  RotateAroundZInDegrees(v.vertex * v.color.b, uIntensity * -270.0);
            v.vertex = pos;
		}

		void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv = IN.uv_MainTex;
            float4 albTex = tex2D(uAlbTex, uv);
            float4 albTex2 = tex2D(uAlbTex2, uv);
            float3 norTex = UnpackNormal(tex2D(uNorTex, uv));
            float2 metRou = tex2D(uMetRou, uv);
            float emitTex = tex2D(uEmitTex, uv).r;
            //---
            float maskTex = IN.vertColor.r * tex2D(uMaskTex, uv * uMaskTex_ST.xy + uMaskTex_ST.zw).r;
            float dissove     = step(maskTex, uIntensity);
            float dissoveEdge = step(maskTex, uIntensity + 0.01);
            //POST CHANGE TEX---
            float myTime = floor(uIntensity) * _SinTime.w;
            float dissove2     = step(maskTex, myTime);
            float dissoveEdge2 = step(maskTex, myTime + 0.01);
            float4 mainTex = lerp(albTex, albTex2, dissoveEdge2+dissove2);
            //---
            float4 color = lerp(mainTex, uEmitColor, dissoveEdge - dissove );

            if (dissoveEdge < 0.1) discard;

			o.Albedo = color;
            o.Normal = norTex;
            o.Metallic = metRou.r;
            o.Smoothness = metRou.g;
            o.Emission = emitTex * uEmitColor;

		}
		ENDCG
	}
	FallBack "Diffuse"
}
