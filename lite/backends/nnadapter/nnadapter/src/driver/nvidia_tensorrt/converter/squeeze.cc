// Copyright (c) 2022 PaddlePaddle Authors. All Rights Reserved.
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

#include "operation/squeeze.h"
#include <algorithm>
#include <iostream>
#include "driver/nvidia_tensorrt/converter/converter.h"
#include "utility/debug.h"
#include "utility/logging.h"
#include "utility/modeling.h"
namespace nnadapter {
namespace nvidia_tensorrt {

int ConvertSqueeze(Converter* converter, core::Operation* operation) {
  SQUEEZE_OPERATION_EXTRACT_INPUTS_OUTPUTS

  // Convert to trt tensors and node
  auto input_tensor = converter->GetMappedTensor(input_operand);
  if (!input_tensor) {
    input_tensor = converter->ConvertOperand(input_operand);
  }
  auto squeeze_layer = converter->network()->addShuffle(*input_tensor);
  NNADAPTER_CHECK(!IsOperandWithDynamicShape(input_operand));
  nvinfer1::Dims out_dims;
  out_dims.nbDims = output_operand->type.dimensions.count;
  memcpy(&out_dims.d[0],
         output_operand->type.dimensions.data,
         sizeof(int32_t) * out_dims.nbDims);
  squeeze_layer->setReshapeDimensions(out_dims);
  auto output_tensor = squeeze_layer->getOutput(0);
  converter->UpdateTensorMap(output_operand, output_tensor);
  return NNADAPTER_NO_ERROR;
}

}  // namespace nvidia_tensorrt
}  // namespace nnadapter
