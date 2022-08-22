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

#include "../../../src/ops/matrices/mat4x4.h"
#include "../../../src/objects/containers/map.h"

#ifdef __PEN_MAC_IOS__
#import <simd/simd.h>

extern "C" {

    /*BatchVertexData already defined in renderer.h*/
    struct BatchVertexData {
        simd::float3 position;
        simd::float4 color;
        simd::float2 texCoord;
        simd::float1 texId;
    };

    struct IOSUniformData {
        simd::float4x4 uMVP;
    };

    struct IOSInstanceData {
        simd::float3 uInstancedOffsets;
    };

    /*----mac_ios_view_delegate----*/
    void MapMacIOSUpdateUniforms(pen::Mat4x4 mvp);
    void MapMacIOSSubmitBatch(unsigned int layerId, BatchVertexData* data, int size);
    void MapMacIOSRender(unsigned int shapeType, int indexCount, unsigned int layerId, unsigned int instanceCount);
    void MapMacIOSBackground(float r, float g, float b, float a);
    /*----mac_ios_view_delegate----*/

    /*----mac_ios_vertex_buffer----*/
    void MapMacPenMacIOSVertexBufferInit(unsigned int layerId, BatchVertexData* data, unsigned int size);
    void MapMacPenMacIOSVertexBufferDestroy(unsigned int layerId);
    /*----mac_ios_vertex_buffer----*/

    /*----mac_ios_index_buffer----*/
    void MapMacPenMacIOSIndexBufferInit(unsigned int layerId, int* data, unsigned int count);
    void MapMacPenMacIOSIndexBufferDestroy(unsigned int layerId);
    /*----mac_ios_index_buffer----*/

    /*----mac_ios_shader----*/
    void MapMacPenMacIOSShaderInit(const char* shaderProgram, unsigned int type);
    void MapMacIOSUpdateInstanceUniform(IOSInstanceData* data);
    /*----mac_ios_shader----*/

    /*----mac_ios_texture----*/
    void MapMacIOSInitializeTexture(unsigned int texWidth, unsigned int texHeight, unsigned int type, unsigned int texSlot, unsigned char* textureData);
    void MapMacIOSLoadTexture(const char* path, const char* mimeType, unsigned int texSlot);
    void MapMacIOSUpdatePixels();
    /*----mac_ios_texture----*/

    /*----mac_ios_util----*/
    const char* MapMacIOSLoadAsset(const char* path, const char* mimeType);
    /*----mac_ios_util----*/

    /*----mac_ios_central_bluetooth----*/
    void MapMacPenMacIOSCentralBluetoothAddDevice(const char* device);
    void MapMacPenMacIOSCentralBluetoothScan();
    void MapMacPenMacIOSCentralBluetoothStop();
    unsigned int MapMacPenMacIOSCentralBluetoothGetCountOfPeripherals();
    const char* MapMacPenMacIOSCentralBluetoothGetPeripheral(unsigned int index);
    void MapMacPenMacIOSCentralBluetoothConnect(const char* device, const char* deviceCharacteristicDescriptor);
    void MapMacPenMacIOSCentralBluetoothRead(const char* device);
    void MapMacPenMacIOSCentralBluetoothWrite(char* data, long length);
    void MapMacPenMacIOSCentralBluetoothDisconnect(const char* device);
    /*----mac_ios_central_bluetooth----*/

    /*----mac_ios_peripheral_bluetooth----*/
    void MapMacPenMacIOSPeripheralBluetoothAddService(const char* service, const char* characteristic, char* value, long length, unsigned int type);
    void MapMacPenMacIOSPeripheralBluetoothUpdateCharacteristicValue(const char* service, const char* characteristic, char* value);
    /*----mac_ios_peripheral_bluetooth----*/

    /*----mac_ios_http----*/
    void MapMacPenMacIOSHttpRequest(const char* url, unsigned int type, pen::Map<std::string,std::string>* httpBody = nullptr);
    /*----mac_ios_http----*/

    /*----mac_ios_socket----*/
    void MapMacPenMacIOSSocketConnect(const char* url);
    void MapMacPenMacIOSSocketSend(char* data, long length);
    void MapMacPenMacIOSSocketReceive();
    /*----mac_ios_socket----*/

    /*----mac_ios_database----*/
    void MapMacPenMacIOSDatabaseStart(const char* database, const char* table);
    void MapMacPenMacIOSDatabaseCreateTable(const char* table);
    void MapMacPenMacIOSDatabaseInsert(const char* table, const char* key, const char* value);
    char* MapMacPenMacIOSDatabaseGet(const char* table, const char* key);
    void MapMacPenMacIOSDatabaseUpdate(const char* table, const char* key, const char* value);
    void MapMacPenMacIOSDatabaseDelete(const char* table, const char* key);
    void MapMacPenMacIOSDatabaseClear(const char* table);
    void MapMacPenMacIOSDatabaseDrop(const char* table);
    /*----mac_ios_database----*/

    /*----mac_ios_sound----*/
    void MapMacPenMacIOSSoundPlay(const char* file, unsigned int loopNum);
    void MapMacPenMacIOSSoundPause(const char* file);
    void MapMacPenMacIOSSoundStop(const char* file);
    void MapMacPenMacIOSSoundRemove(const char* file);
    /*----mac_ios_sound----*/
};
#endif