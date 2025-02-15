// Copyright (c) 2020 PaddlePaddle Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "lite/kernels/arm/pow_compute.h"
#include "lite/backends/arm/math/funcs.h"
#ifdef ENABLE_ARM_FP16
#include "lite/backends/arm/math/fp16/funcs_fp16.h"
#endif

namespace paddle {
namespace lite {
namespace kernels {
namespace arm {
template <>
void PowCompute<PRECISION(kFloat), PRECISION(kFloat)>::Run() {
  auto& param = Param<operators::PowParam>();
  const float* x_data = param.X->data<float>();
  float* output_data = param.Out->mutable_data<float>();
  DDim x_dims = param.X->dims();
  float scale = 1.0;
  float shift = 0.0;
  float power = param.factor;

  lite::arm::math::power(
      x_data, output_data, x_dims.production(), scale, shift, power);
}

#ifdef ENABLE_ARM_FP16
template <>
void PowCompute<PRECISION(kFP16), PRECISION(kFP16)>::Run() {
  auto& param = Param<operators::PowParam>();
  const float* x_data = param.X->data<float>();
  float* output_data = param.Out->mutable_data<float>();
  DDim x_dims = param.X->dims();
  float scale = 1.0;
  float shift = 0.0;
  float power = param.factor;

  lite::arm::math::power(
      x_data, output_data, x_dims.production(), scale, shift, power);
}
#endif

}  // namespace arm
}  // namespace kernels
}  // namespace lite
}  // namespace paddle

#ifdef ENABLE_ARM_FP16
typedef paddle::lite::kernels::arm::PowCompute<PRECISION(kFP16),
                                               PRECISION(kFP16)>
    PowFp16;
REGISTER_LITE_KERNEL(pow, kARM, kFP16, kNCHW, PowFp16, def)
    .BindInput("X", {LiteType::GetTensorTy(TARGET(kARM), PRECISION(kFP16))})
    .BindOutput("Out", {LiteType::GetTensorTy(TARGET(kARM), PRECISION(kFP16))})
    .Finalize();
#endif  // ENABLE_ARM_FP16
typedef paddle::lite::kernels::arm::PowCompute<PRECISION(kFloat),
                                               PRECISION(kFloat)>
    PowFp32;
REGISTER_LITE_KERNEL(pow, kARM, kFloat, kNCHW, PowFp32, def)
    .BindInput("X", {LiteType::GetTensorTy(TARGET(kARM), PRECISION(kFloat))})
    .BindOutput("Out", {LiteType::GetTensorTy(TARGET(kARM), PRECISION(kFloat))})
    .Finalize();
