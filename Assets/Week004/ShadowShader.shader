Shader "Custom/ShadowShader"
{
    Properties
    {
        uColor("uColor", Color) = (1,1,1,1)
		_BaseColor("BaseColor", Color) = (1,1,1,1)
		_Ambient ("Ambient",    Color) = (0.1, 0.1, 0.1, 1)
		_Diffuse ("Diffuse",    Range(0,1)) = 0.7
		_Specular("Specular",   Range(0,1)) = 0.25
		_Shininess("Shininess", Range(0.1, 256)) = 32
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "MyCommon.hlsl"

            struct Attributes
            {
				float4 positionOS   : POSITION;
				float3 normal : NORMAL;
            };

            struct Varyings
            {
				float4 positionHCS : SV_POSITION;
				float3 positionWS  : TEXCOORD8;
				float3 viewDir     : TEXCOORD9;
				float3 normal      : NORMAL;
            };

			struct SurfaceInfo {
				float4 baseColor;
				float3 ambient;
				float diffuse;
				float specular;
				float shininess;
				float3 normal;
			};

            //UNIFORM
            CBUFFER_START(UnityPerDraw)
			float4 _BaseColor;
			float4 _Ambient;
			float _Diffuse;
			float _Specular;
			float _Shininess;

            static const int kMaxLightCount = 8;

            int		uLightCount;
			float4	uLightColor[kMaxLightCount];
			float4	uLightPos[kMaxLightCount];
			float4	uLightDir[kMaxLightCount];
			float4	uLightParam[kMaxLightCount];

            CBUFFER_END 

			Varyings vert (Attributes i)
			{
				Varyings o;
				o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
				o.positionWS  = TransformObjectToWorld(i.positionOS.xyz);
				o.normal = i.normal;
				return o;
			}

			float4 computeLighting(Varyings i, SurfaceInfo s) {
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.positionWS);

				int lightCount = min(kMaxLightCount, uLightCount);
				float4 o = s.baseColor * float4(s.ambient, 1);

				for (int j = 0; j < lightCount; j++) {
					float3 lightColor     = uLightColor[j].rgb;
					float  lightIntensity = uLightColor[j].a;

					float3 lightPos       = uLightPos[j].xyz;

					float3 lightDir       = uLightDir[j].xyz;
					float  isDirectional  = uLightDir[j].w;

					float3 lightPosDir = i.positionWS - lightPos;

					float3 L = lerp(lightPosDir, lightDir, isDirectional);
					float  lightSqDis = dot(L,L) * (1 - isDirectional);

					L = normalize(L);

					float  isSpotlight         = uLightParam[j].x;
					float  lightSpotAngle      = uLightParam[j].y;
					float  lightInnerSpotAngle = uLightParam[j].z;
					float  lightRange          = uLightParam[j].w;

					float diffuse  = s.diffuse * max(dot(-L, s.normal), 0.0);

					float3 reflectDir = reflect(L, s.normal);
					float specular = s.specular * pow(max(dot(viewDir, reflectDir), 0.0), s.shininess);

					float attenuation = 1 - saturate(lightSqDis / (lightRange * lightRange));
					float intensity = lightIntensity * attenuation;

					if (isSpotlight > 0) {
						intensity *= smoothstep(lightSpotAngle, lightInnerSpotAngle, dot(lightDir, L));
					}

					o.rgb += (diffuse + specular) * intensity * s.baseColor * lightColor;
				}

				return o;
			}

			float4 frag (Varyings i) : SV_Target
			{
				SurfaceInfo s;
				s.baseColor = _BaseColor;
				s.ambient   = _Ambient;
				s.diffuse   = _Diffuse;
				s.specular  = _Specular;
				s.shininess = _Shininess;
				s.normal = normalize(i.normal);
				return computeLighting(i, s);
			}
            ENDHLSL
        }
    }
}