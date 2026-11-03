//
// Rain Maker (c) 2015 Digital Ruby, LLC
// http://www.digitalruby.com
//
// Modified for Unity 6:
// - Uses a ForwardBase pass instead of the legacy vertex-lit pass ("LightMode"="Vertex"),
//   reading the main directional light, ambient (spherical harmonics) and up to 4 vertex point lights.
// - Adds _MinLight so the rain stays visible in dark scenes, because both color and alpha scale with light.
// - Replaces fixed-function AlphaTest with clip() and updates the fallback shader name.
//

Shader "Custom/RainShader"
{
    Properties
	{
		_MainTex ("Color (RGB) Alpha (A)", 2D) = "gray" {}
		_TintColor ("Tint Color (RGB)", Color) = (1, 1, 1, 1)
		_PointSpotLightMultiplier ("Point/Spot Light Multiplier", Range (0, 10)) = 2
		_DirectionalLightMultiplier ("Directional Light Multiplier", Range (0, 10)) = 1
		_InvFade ("Soft Particles Factor", Range(0.01, 100.0)) = 1.0
		_AmbientLightMultiplier ("Ambient light multiplier", Range(0, 1)) = 0.25
		_MinLight ("Minimum light (keeps rain visible in dark scenes)", Range(0, 1)) = 0.3
    }

    SubShader
	{
        Tags { "QUEUE"="Transparent" "IGNOREPROJECTOR"="true" "RenderType"="Transparent" }
		LOD 100

        Pass
		{
			Tags { "LightMode"="ForwardBase" }
			ZWrite Off
			Cull Back
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma multi_compile_particles
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _TintColor;
			float _DirectionalLightMultiplier;
			float _PointSpotLightMultiplier;
			float _AmbientLightMultiplier;
			float _MinLight;

			#if defined(SOFTPARTICLES_ON)
			float _InvFade;
			#endif

			struct appdata_t
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};

		    struct v2f
            {
                half2 uv_MainTex : TEXCOORD0;
                fixed4 color : COLOR0;
                float4 pos : SV_POSITION;
				#if defined(SOFTPARTICLES_ON)
                float4 projPos : TEXCOORD1;
                #endif
            };

            float3 LightForVertex(float4 vertex)
            {
                float3 worldPos = mul(unity_ObjectToWorld, vertex).xyz;

				// ambient light (environment lighting, including baked skybox ambient)
                float3 lightColor = ShadeSH9(float4(0, 1, 0, 1)) * _AmbientLightMultiplier;

				// main directional light, reduced as it goes below the horizon (same behavior as the original shader)
				float multiplier = saturate((_WorldSpaceLightPos0.y * 2) + 1);
				lightColor += _LightColor0.rgb * multiplier * _DirectionalLightMultiplier;

				#if defined(VERTEXLIGHT_ON)
				// up to 4 point/spot lights, attenuation only (rain drops have no normal)
				for (int index = 0; index < 4; index++)
				{
					float3 toLight = float3(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index]) - worldPos;
					float lengthSq = dot(toLight, toLight);
					float atten = 1.0 / (1.0 + (lengthSq * unity_4LightAtten0[index]));
					lightColor += unity_LightColor[index].rgb * atten * _PointSpotLightMultiplier;
				}
				#endif

                return max(lightColor, _MinLight.xxx);
            }

            float4 _MainTex_ST;

            v2f vert(appdata_t v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.color = fixed4(LightForVertex(v.vertex), 1) * v.color * _TintColor;

				// o.color = v.color * _TintColor; // temp if you want to disable lighting

				// make sure the alpha scales down with the light
				o.color *= (min(o.color.rgb, _TintColor.a).r / _TintColor.a);

				#if defined(SOFTPARTICLES_ON)
                o.projPos = ComputeScreenPos(o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                #endif

                return o;
            }

			#if defined(SOFTPARTICLES_ON)
			sampler2D _CameraDepthTexture;
			#endif

			sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
			{
				#if defined(SOFTPARTICLES_ON)
				float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				float partZ = i.projPos.z;
				i.color.a *= saturate(_InvFade * (sceneZ - partZ));
				#endif

				fixed4 col = tex2D(_MainTex, i.uv_MainTex) * i.color;
				clip(col.a - 0.01);
				return col;
            }
            ENDCG
        }
    }

    Fallback "Legacy Shaders/Particles/Alpha Blended"
}
