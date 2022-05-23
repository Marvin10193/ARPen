/*
 Taken from the ShareARExperience Demo by Apple

Abstract:
A group of render pipeline that the renderer uses.
*/

import Metal

// MARK: - PipelineStates
struct PipelineStates {
    
    let videoStream: MTLRenderPipelineState
        
    init(device: MTLDevice, renderDestination: RenderDestination) {

        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to create default library with device: \(device.description)")
        }
        
        videoStream = MetalUtils.makeRenderPipelineState(device: device, label: "Video Stream") { descriptor in
            descriptor.vertexFunction = library.makeFunction(name: "imageVertexTransform")
            descriptor.fragmentFunction = library.makeFunction(name: "imageFragmentShader")
            descriptor.vertexDescriptor = VertexDescriptors.imagePlane
            descriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
            descriptor.depthAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
            descriptor.stencilAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        }
    }
}

