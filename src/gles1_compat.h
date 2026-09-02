/*
    TE4 iOS port: fixed-function emulation over OpenGL ES 2.0.

    (Historical note: this layer first targeted ES 1.1, but modern iOS
    simulators only hand out ES 2.0 contexts, so the fixed-function
    pipeline the engine uses is emulated here instead. The TE4_GLES1
    define name is kept to avoid churn.)

    Included from display_sdl.h/tgl.h when TE4_GLES1 is defined. Provides:
      - the GLES2 headers (iOS or vendored Khronos for host syntax checks)
      - a C-side matrix stack + client-array capture + one shader program
        that together emulate the ES1 fixed-function pipeline the engine
        draws with (glMatrixMode/glOrtho/gl*Pointer/GL_QUADS/...)
      - EXT framebuffer names -> ES2 core, with "bind 0" remapped to the
        SDL screen framebuffer (iOS has no default framebuffer 0)
      - texture bookkeeping for the glGetTexLevelParameteriv/glGetTexImage
        queries ES lacks
      - a minimal GLEW substitute (capabilities off; engine has fallbacks)
      - inert ARB shader stubs and small GLU replacements (menu planet)
*/
#ifndef TE4_GLES1_COMPAT_H
#define TE4_GLES1_COMPAT_H

#if defined(__APPLE__) && !defined(TE4_GLES_CHECK)
#include <TargetConditionals.h>
#endif

#ifdef TE4_GLES_CHECK
/* host-side syntax checking against vendored Khronos headers */
#include "ios/GLES2/gl2.h"
#include "ios/GLES2/gl2ext.h"
#else
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* ---- types desktop GL has and GLES2 lacks ---- */
typedef double GLdouble;
typedef GLuint GLhandleARB;
typedef char GLcharARB;

/* ---- fixed-function constants the engine uses ---- */
#define GL_QUADS 0x0007              /* emulated in te4_glDrawArrays */
#define GL_MODELVIEW 0x1700
#define GL_PROJECTION 0x1701
#define GL_VERTEX_ARRAY 0x8074
#define GL_COLOR_ARRAY 0x8076
#define GL_TEXTURE_COORD_ARRAY 0x8078
#define GL_CLAMP GL_CLAMP_TO_EDGE
#define GL_RGB8 GL_RGB               /* ES: internalformat must equal format */
#define GL_RGBA8 GL_RGBA
#ifndef GL_BGRA
#define GL_BGRA 0x80E1               /* GL_APPLE/EXT_texture_format_BGRA8888 */
#endif
#define GL_BGR 0x80E0                /* readback shim repacks to 3-byte reversed RGB */
#define GL_TEXTURE_3D 0x806F         /* uploads no-op'd; only shader paths sample these */
#define GL_TEXTURE_WRAP_R 0x8072
#define GL_TEXTURE_WIDTH 0x1000
#define GL_TEXTURE_HEIGHT 0x1001
#define GL_VIEWPORT_BIT 0x00000800
#define GL_FRAMEBUFFER_EXT GL_FRAMEBUFFER
#define GL_COLOR_ATTACHMENT0_EXT GL_COLOR_ATTACHMENT0
#define GL_COLOR_ATTACHMENT1_EXT 0x8CE1  /* MRT never active without shaders */
#define GL_FRAMEBUFFER_COMPLETE_EXT GL_FRAMEBUFFER_COMPLETE

/* ---- fixed-function emulation (gles1_compat.c) ---- */
void te4_gles_init(void);            /* call with context current; compiles the pipeline shader */
void te4_glMatrixMode(GLenum mode);
void te4_glLoadIdentity(void);
void te4_glPushMatrix(void);
void te4_glPopMatrix(void);
void te4_glTranslatef(GLfloat x, GLfloat y, GLfloat z);
void te4_glScalef(GLfloat x, GLfloat y, GLfloat z);
void te4_glRotatef(GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
void te4_glOrtho(GLdouble l, GLdouble r, GLdouble b, GLdouble t, GLdouble n, GLdouble f);
void te4_glVertexPointer(GLint size, GLenum type, GLsizei stride, const void *ptr);
void te4_glTexCoordPointer(GLint size, GLenum type, GLsizei stride, const void *ptr);
void te4_glColorPointer(GLint size, GLenum type, GLsizei stride, const void *ptr);
void te4_glEnableClientState(GLenum array);
void te4_glDisableClientState(GLenum array);
void te4_glColor4f(GLfloat r, GLfloat g, GLfloat b, GLfloat a);
void te4_glEnable(GLenum cap);
void te4_glDisable(GLenum cap);
void te4_glDrawArrays(GLenum mode, GLint first, GLsizei count);
void te4_glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void *pixels);
void te4_glPushAttrib(GLbitfield mask);   /* engine only ever saves the viewport */
void te4_glPopAttrib(void);
void te4_glGetTexLevelParameteriv(GLenum target, GLint level, GLenum pname, GLint *params);
void te4_glGetTexImage(GLenum target, GLint level, GLenum format, GLenum type, void *pixels);
void te4_glTexImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const void *pixels);
void te4_glDrawBuffers(GLsizei n, const GLenum *bufs);
void te4_glReadPixels_compat(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, void *pixels);
void te4_glClearDepth(GLdouble d);
void te4_glActiveTexture(GLenum unit);
#define glActiveTexture te4_glActiveTexture

#define glMatrixMode te4_glMatrixMode
#define glLoadIdentity te4_glLoadIdentity
#define glPushMatrix te4_glPushMatrix
#define glPopMatrix te4_glPopMatrix
#define glTranslatef te4_glTranslatef
#define glScalef te4_glScalef
#define glRotatef te4_glRotatef
#define glOrtho te4_glOrtho
#define glVertexPointer te4_glVertexPointer
#define glTexCoordPointer te4_glTexCoordPointer
#define glColorPointer te4_glColorPointer
#define glEnableClientState te4_glEnableClientState
#define glDisableClientState te4_glDisableClientState
#define glColor4f te4_glColor4f
#define glEnable te4_glEnable
#define glDisable te4_glDisable
#define glDrawArrays te4_glDrawArrays
#define glTexImage2D te4_glTexImage2D
#define glTexSubImage2D te4_glTexSubImage2D
#define glPushAttrib te4_glPushAttrib
#define glPopAttrib te4_glPopAttrib
#define glGetTexLevelParameteriv te4_glGetTexLevelParameteriv
#define glGetTexImage te4_glGetTexImage
#define glTexImage3D te4_glTexImage3D
#define glDrawBuffers te4_glDrawBuffers
#define glReadPixels te4_glReadPixels_compat
#define glClearDepth te4_glClearDepth

/* ---- framebuffers: EXT names -> ES2 core, with 0 remapped ---- */
extern GLuint te4_gles1_default_fbo;
void te4_gles1_capture_default_fbo(void);
void te4_glBindFramebuffer(GLenum target, GLuint framebuffer);
#define glGenFramebuffersEXT glGenFramebuffers
#define glDeleteFramebuffersEXT glDeleteFramebuffers
#define glBindFramebufferEXT te4_glBindFramebuffer
#define glFramebufferTexture2DEXT glFramebufferTexture2D
#define glCheckFramebufferStatusEXT glCheckFramebufferStatus

/* ---- ARB shader object API: link-satisfying stubs (never active) ---- */
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
void te4_stub_GetInfoLogARB(GLhandleARB obj, GLsizei maxLength, GLsizei *length, GLcharARB *infoLog);
void te4_stub_ValidateProgramARB(GLhandleARB programObj);

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
#define glGetInfoLogARB te4_stub_GetInfoLogARB
#define glValidateProgramARB te4_stub_ValidateProgramARB

/* (GL_COMPILE_STATUS, GL_VALIDATE_STATUS, GL_FLOAT_VEC*, GL_SAMPLER_2D
 * etc. are core in ES2 - only the ARB-suffixed spellings need defining) */
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
#define GLEW_EXT_framebuffer_object 1   /* core in ES2 */
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
