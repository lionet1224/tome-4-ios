/*
    TE4 iOS port: OpenGL ES 1.1 compatibility layer.

    The engine's GL usage is GLES1-shaped (client vertex arrays + matrix
    stack, no glBegin) but written against desktop GL + GLEW. This header,
    included from display_sdl.h when TE4_GLES1 is defined, provides:
      - the GLES1 headers (iOS or vendored Khronos for host syntax checks)
      - constant/entry-point mappings for the deltas (glOrtho->glOrthof,
        EXT FBOs -> OES FBOs, GL_QUADS emulation, ...)
      - a minimal GLEW substitute (all capability macros 0: the engine
        already carries no-shader/no-multitexture fallback paths)
      - stubs for desktop-only entry points that only run behind those
        capability flags (ARB shaders, glDrawBuffers, glTexImage3D)
      - small GLU replacements (error strings + the boot-screen sphere)
*/
#ifndef TE4_GLES1_COMPAT_H
#define TE4_GLES1_COMPAT_H

#if defined(__APPLE__) && !defined(TE4_GLES_CHECK)
#include <TargetConditionals.h>
#endif

#ifdef TE4_GLES_CHECK
/* host-side syntax checking against vendored Khronos headers */
#include "ios/GLES/gl.h"
#include "ios/GLES/glext.h"
#else
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* ---- types desktop GL has and GLES1 lacks ---- */
typedef double GLdouble;
typedef char GLchar;
typedef GLuint GLhandleARB;
typedef char GLcharARB;

/* ---- constants ---- */
#define GL_QUADS 0x0007              /* emulated in te4_glDrawArrays */
#define GL_CLAMP GL_CLAMP_TO_EDGE
#define GL_RGB8 GL_RGB               /* ES1: internalformat must equal format */
#define GL_RGBA8 GL_RGBA
#ifndef GL_BGRA
#define GL_BGRA 0x80E1               /* GL_APPLE_texture_format_BGRA8888 / GL_BGRA_EXT */
#endif
#define GL_BGR 0x80E0                /* readback shim repacks to 3-byte reversed RGB */
#define GL_COMPILE_STATUS 0x8B81
#define GL_LINK_STATUS 0x8B82
#define GL_VALIDATE_STATUS 0x8B83
#define GL_INFO_LOG_LENGTH 0x8B84
#define GL_ACTIVE_UNIFORMS 0x8B86
#define GL_VERTEX_SHADER 0x8B31
#define GL_FRAGMENT_SHADER 0x8B30
#define GL_FLOAT_VEC2 0x8B50
#define GL_FLOAT_VEC3 0x8B51
#define GL_FLOAT_VEC4 0x8B52
#define GL_SAMPLER_2D 0x8B5E
#define GL_COLOR_ATTACHMENT0 GL_COLOR_ATTACHMENT0_OES
#define GL_TEXTURE_3D 0x806F         /* uploads no-op'd; only shader paths sample these */
#define GL_TEXTURE_WRAP_R 0x8072
#define GL_TEXTURE_WIDTH 0x1000
#define GL_TEXTURE_HEIGHT 0x1001
#define GL_VIEWPORT_BIT 0x00000800
#ifndef GL_FRAMEBUFFER_EXT
#define GL_FRAMEBUFFER_EXT GL_FRAMEBUFFER_OES
#define GL_COLOR_ATTACHMENT0_EXT GL_COLOR_ATTACHMENT0_OES
#define GL_FRAMEBUFFER_COMPLETE_EXT GL_FRAMEBUFFER_COMPLETE_OES
#endif
#define GL_COLOR_ATTACHMENT1_EXT 0x8CE1  /* MRT never active without shaders */

/* ---- simple renames ---- */
#define glOrtho(l, r, b, t, n, f) glOrthof((GLfloat)(l), (GLfloat)(r), (GLfloat)(b), (GLfloat)(t), (GLfloat)(n), (GLfloat)(f))
#define glClearDepth(d) glClearDepthf((GLfloat)(d))

/* ---- OES framebuffer objects ---- */
#define glGenFramebuffersEXT glGenFramebuffersOES
#define glDeleteFramebuffersEXT glDeleteFramebuffersOES
#define glBindFramebufferEXT glBindFramebufferOES
#define glFramebufferTexture2DEXT glFramebufferTexture2DOES
#define glCheckFramebufferStatusEXT glCheckFramebufferStatusOES

/* ---- shimmed entry points (gles1_compat.c) ---- */
void te4_glDrawArrays(GLenum mode, GLint first, GLsizei count);
void te4_glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void *pixels);
void te4_glPushAttrib(GLbitfield mask);   /* engine only ever passes GL_VIEWPORT_BIT */
void te4_glPopAttrib(void);
void te4_glGetTexLevelParameteriv(GLenum target, GLint level, GLenum pname, GLint *params);
void te4_glGetTexImage(GLenum target, GLint level, GLenum format, GLenum type, void *pixels);
void te4_glTexImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const void *pixels);
void te4_glDrawBuffers(GLsizei n, const GLenum *bufs);
void te4_glReadPixels_compat(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, void *pixels);

#define glDrawArrays te4_glDrawArrays        /* tgl.h re-wraps this; order matters, see display_sdl.h */
#define glTexImage2D te4_glTexImage2D
#define glPushAttrib te4_glPushAttrib
#define glPopAttrib te4_glPopAttrib
#define glGetTexLevelParameteriv te4_glGetTexLevelParameteriv
#define glGetTexImage te4_glGetTexImage
#define glTexImage3D te4_glTexImage3D
#define glDrawBuffers te4_glDrawBuffers
#define glReadPixels te4_glReadPixels_compat

/* ---- ARB shader object API: link-satisfying stubs. shaders_active is
   forced FALSE (see GLEW substitute below), and core.shader reports
   inactive to Lua, so these should never execute; if one does it returns
   failure values rather than crashing. ---- */
GLhandleARB te4_stub_CreateShaderObjectARB(GLenum shaderType);
GLhandleARB te4_stub_CreateProgramObjectARB(void);
void te4_stub_ShaderSourceARB(GLhandleARB shaderObj, GLsizei count, const GLcharARB **string, const GLint *length);
void te4_stub_CompileShaderARB(GLhandleARB shaderObj);
void te4_stub_LinkProgramARB(GLhandleARB programObj);
void te4_stub_AttachObjectARB(GLhandleARB containerObj, GLhandleARB obj);
void te4_stub_DetachObjectARB(GLhandleARB containerObj, GLhandleARB attachedObj);
void te4_stub_DeleteObjectARB(GLhandleARB obj);
void te4_stub_UseProgramObjectARB(GLhandleARB programObj);
GLint te4_stub_GetUniformLocationARB(GLhandleARB programObj, const GLcharARB *name);
void te4_stub_GetObjectParameterivARB(GLhandleARB obj, GLenum pname, GLint *params);
void te4_stub_GetActiveUniformARB(GLhandleARB programObj, GLuint index, GLsizei maxLength, GLsizei *length, GLint *size, GLenum *type, GLcharARB *name);
void te4_stub_Uniform1fvARB(GLint location, GLsizei count, const GLfloat *value);
void te4_stub_Uniform2fvARB(GLint location, GLsizei count, const GLfloat *value);
void te4_stub_Uniform3fvARB(GLint location, GLsizei count, const GLfloat *value);
void te4_stub_Uniform4fvARB(GLint location, GLsizei count, const GLfloat *value);
void te4_stub_Uniform1ivARB(GLint location, GLsizei count, const GLint *value);

#define glCreateShaderObjectARB te4_stub_CreateShaderObjectARB
#define glCreateProgramObjectARB te4_stub_CreateProgramObjectARB
#define glShaderSourceARB te4_stub_ShaderSourceARB
#define glCompileShaderARB te4_stub_CompileShaderARB
#define glLinkProgramARB te4_stub_LinkProgramARB
#define glAttachObjectARB te4_stub_AttachObjectARB
#define glDetachObjectARB te4_stub_DetachObjectARB
#define glDeleteObjectARB te4_stub_DeleteObjectARB
#define glUseProgramObjectARB te4_stub_UseProgramObjectARB
#define glGetUniformLocationARB te4_stub_GetUniformLocationARB
#define glGetObjectParameterivARB te4_stub_GetObjectParameterivARB
#define glGetActiveUniformARB te4_stub_GetActiveUniformARB
#define glUniform1fvARB te4_stub_Uniform1fvARB
#define glUniform2fvARB te4_stub_Uniform2fvARB
#define glUniform3fvARB te4_stub_Uniform3fvARB
#define glUniform4fvARB te4_stub_Uniform4fvARB
#define glUniform1ivARB te4_stub_Uniform1ivARB

#define GL_OBJECT_COMPILE_STATUS_ARB 0x8B81
#define GL_OBJECT_LINK_STATUS_ARB 0x8B82
#define GL_OBJECT_INFO_LOG_LENGTH_ARB 0x8B84
#define GL_OBJECT_ACTIVE_UNIFORMS_ARB 0x8B86
#define GL_VERTEX_SHADER_ARB 0x8B31
#define GL_FRAGMENT_SHADER_ARB 0x8B30

/* ---- GLEW substitute ---- */
#define GLEW_OK 0
#define glewInit() (GLEW_OK)
#define glewGetErrorString(e) ((const GLubyte*)"glew-substitute")
#define GLEW_ARB_multitexture 0
#define GLEW_ARB_shader_objects 0
#define GLEW_ARB_framebuffer_object 0
#define GLEW_EXT_framebuffer_object 1   /* via GL_OES_framebuffer_object, always present on iOS */
#define GLEW_EXT_gpu_shader4 0
#define GLEW_VERSION_2_1 0

/* ---- GLU replacement ---- */
typedef struct te4_GLUquadric GLUquadric;
typedef struct te4_GLUquadric GLUquadricObj;
#define GLU_SMOOTH 100000
GLUquadric *te4_gluNewQuadric(void);
void te4_gluDeleteQuadric(GLUquadric *q);
void te4_gluQuadricNormals(GLUquadric *q, GLenum normals);
void te4_gluQuadricTexture(GLUquadric *q, GLboolean texture);
void te4_gluSphere(GLUquadric *q, GLdouble radius, GLint slices, GLint stacks);
const GLubyte *te4_gluErrorString(GLenum error);
#define gluNewQuadric te4_gluNewQuadric
#define gluDeleteQuadric te4_gluDeleteQuadric
#define gluQuadricNormals te4_gluQuadricNormals
#define gluQuadricTexture te4_gluQuadricTexture
#define gluSphere te4_gluSphere
#define gluErrorString te4_gluErrorString

#ifdef __cplusplus
}
#endif

#endif /* TE4_GLES1_COMPAT_H */
