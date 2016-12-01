/*
MIT License

Copyright 2015, Gregg Tavares.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.
    * Neither the name of Gregg Tavares. nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
Shader "Custom/HSLRangeShader"
{
    Properties
    {
       _MainTex ("Sprite Texture", 2D) = "white" {}
       _Color ("Alpha Color Key", Color) = (0,0,0,1)
       _HSLRangeMin ("HSL Affect Range Min", Range(0, 1)) = 0
       _HSLRangeMax ("HSL Affect Range Max", Range(0, 1)) = 1
       _HSLAAdjust ("HSLA Adjust", Vector) = (0, 0, 0, 0)
       _StencilComp ("Stencil Comparison", Float) = 8
       _Stencil ("Stencil ID", Float) = 0
       _StencilOp ("Stencil Operation", Float) = 0
       _StencilWriteMask ("Stencil Write Mask", Float) = 255
       _StencilReadMask ("Stencil Read Mask", Float) = 255
       _ColorMask ("Color Mask", Float) = 15
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Pass
        {
            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile DUMMY PIXELSNAP_ON

            sampler2D _MainTex;
            float4 _Color;
            float _HSLRangeMin;
            float _HSLRangeMax;
            float4 _HSLAAdjust;

            struct Vertex
            {
                float4 vertex : POSITION;
                float2 uv_MainTex : TEXCOORD0;
            };

            struct Fragment
            {
                float4 vertex : POSITION;
                float2 uv_MainTex : TEXCOORD0;
            };

            Fragment vert(Vertex v)
            {
                Fragment o;

                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                o.uv_MainTex = v.uv_MainTex;

                return o;
            }


            float Epsilon = 1e-10;

            float3 rgb2hcv(in float3 RGB)
            {
                // Based on work by Sam Hocevar and Emil Persson
                float4 P = lerp(float4(RGB.bg, -1.0, 2.0/3.0), float4(RGB.gb, 0.0, -1.0/3.0), step(RGB.b, RGB.g));
                float4 Q = lerp(float4(P.xyw, RGB.r), float4(RGB.r, P.yzx), step(P.x, RGB.r));
                float C = Q.x - min(Q.w, Q.y);
                float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
                return float3(H, C, Q.x);
            }

            float3 rgb2hsl(in float3 RGB)
            {
                float3 HCV = rgb2hcv(RGB);
                float L = HCV.z - HCV.y * 0.5;
                float S = HCV.y / (1 - abs(L * 2 - 1) + Epsilon);
                return float3(HCV.x, S, L);
            }

            float3 hsl2rgb(float3 c)
            {
                c = float3(frac(c.x), clamp(c.yz, 0.0, 1.0));
                float3 rgb = clamp(abs(fmod(c.x * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
                return c.z + c.y * (rgb - 0.5) * (1.0 - abs(2.0 * c.z - 1.0));
            }

            float4 frag(Fragment IN) : COLOR
            {
                float4 color = tex2D (_MainTex, IN.uv_MainTex);
                float3 hsl = rgb2hsl(color.rgb);
                float affectMult = step(_HSLRangeMin, hsl.r) * step(hsl.r, _HSLRangeMax);
                float3 rgb = hsl2rgb(hsl + _HSLAAdjust.xyz * affectMult);
                return float4(rgb, color.a + _HSLAAdjust.a);
            }

            ENDCG
        }
    }
}
