/*************************************************************************************************
 Copyright 2021 Jamar Phillip

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
*************************************************************************************************/
#pragma once
#include "../state/config.h"
#include "../../dependencies/glad/glad.h"
#include "../core/vertex_array.h"
#include "../core/index_buffer.h"
#include "../core/shader.h"
#include "../ops/vectors/vec3.h"
#include "../ops/vectors/vec4.h"

namespace pen {
	struct BatchVertexData {
		float vertex[3];
		float color[4];
		float texCoord[2];
		float texId;
	};

	class Renderer {
	public:
		static int drawType[7];

		void Clear() const;
		void Background(pen::Vec4 color) const;
		void Draw(const VertexArray& va, const IndexBuffer& ib, int& indexCount, const VertexBuffer& vb, const Shader& shader, int indices, const unsigned int& shapeType) const;
	};
}