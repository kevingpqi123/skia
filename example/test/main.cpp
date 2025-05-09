/////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Tencent is pleased to support the open source community by making tgfx available.
//
//  Copyright (C) 2025 THL A29 Limited, a Tencent company. All rights reserved.
//
//  Licensed under the BSD 3-Clause License (the "License"); you may not use this file except
//  in compliance with the License. You may obtain a copy of the License at
//
//      https://opensource.org/licenses/BSD-3-Clause
//
//  unless required by applicable law or agreed to in writing, software distributed under the
//  license is distributed on an "as is" basis, without warranties or conditions of any kind,
//  either express or implied. see the license for the specific language governing permissions
//  and limitations under the license.
//
/////////////////////////////////////////////////////////////////////////////////////////////////

#include <iostream>


#include "../../include/core/SkSurface.h"
#include "../../include/core/SkCanvas.h"
#include "../../include/core/SkColor.h"
#include "../../include/core/SkGraphics.h"
#include "../../include/core/SkImageInfo.h"
#include "../../include/core/SkPaint.h"
#include "../../include/core/SkRect.h"
#include "../../include/core/SkTypes.h"
#include "../../tools/sk_app/Application.h"
#include "../../tools/sk_app/Window.h"

void test() {
    printf("-----test------\n");
    auto info = SkImageInfo::MakeN32Premul(800, 800);
    auto surface = SkSurfaces::Raster(info);
    SkCanvas* canvas = surface->getCanvas();
    if (!canvas) {
        printf("canvas is null\n");
        return;
    }
    SkPaint paint;
    paint.setAntiAlias(true);

//    canvas->translate(-r.fLeft, -r.fTop);
    canvas->drawRect(SkRect::MakeWH(100, 100), paint);

}

int main(int argc, char** argv) {
    test();
    return 0;
}