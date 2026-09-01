/*
    TE4 iOS port: OpenGL ES 1.1 compatibility layer implementation.
    See gles1_compat.h for the map of what is shimmed and why.
*/
#ifdef TE4_GLES1

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* get the raw GLES API without our own remapping macros */
#define TE4_GLES1_COMPAT_NO_REMAP
#ifdef TE4_GLES_CHECK
#include "ios/GLES/gl.h"
#include "ios/GLES/glext.h"
#else
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#endif

typedef double GLdouble;
typedef GLuint GLhandleARB;
typedef char GLcharARB;

/* tgl.h caches (see tgl.h); we must keep them coherent when we touch
 * pointer/texture state behind the engine's back */
extern int nb_draws;
extern GLuint gl_c_texture;
extern int gl_c_vertices_nb, gl_c_texcoords_nb, gl_c_colors_nb;
extern GLfloat *gl_c_vertices_ptr;
extern GLfloat *gl_c_texcoords_ptr;
extern GLfloat *gl_c_colors_ptr;

/* ------------------------------------------------------------------ */
/* GL_QUADS emulation: 4 vertices -> 6 triangle indices               */
/* ------------------------------------------------------------------ */
#define TE4_GL_QUADS 0x0007
#define TE4_MAX_QUAD_VERTS 65532  /* ushort index space, multiple of 4 */

static GLushort *quad_indices = NULL;
static GLsizei quad_indices_built_for = 0;  /* verts covered, first==0 based */

static void ensure_quad_indices(GLsizei vert_count)
{
	if (vert_count <= quad_indices_built_for) return;
	GLsizei quads = vert_count / 4;
	quad_indices = realloc(quad_indices, quads * 6 * sizeof(GLushort));
	GLsizei q;
	for (q = 0; q < quads; q++) {
		GLushort v = (GLushort)(q * 4);
		GLushort *ix = quad_indices + q * 6;
		ix[0] = v; ix[1] = v + 1; ix[2] = v + 2;
		ix[3] = v; ix[4] = v + 2; ix[5] = v + 3;
	}
	quad_indices_built_for = quads * 4;
}

void te4_glDrawArrays(GLenum mode, GLint first, GLsizei count)
{
	nb_draws++;
	if (mode != TE4_GL_QUADS) {
		glDrawArrays(mode, first, count);
		return;
	}
	if (first != 0) {
		/* engine always draws quads from 0; degrade gracefully if not */
		GLint q;
		for (q = 0; q < count / 4; q++) glDrawArrays(GL_TRIANGLE_FAN, first + q * 4, 4);
		return;
	}
	if (count > TE4_MAX_QUAD_VERTS) {
		static int warned = 0;
		if (!warned++) printf("[GLES1] clamping quad draw of %d verts to %d\n", (int)count, TE4_MAX_QUAD_VERTS);
		count = TE4_MAX_QUAD_VERTS;
	}
	ensure_quad_indices(count);
	glDrawElements(GL_TRIANGLES, (count / 4) * 6, GL_UNSIGNED_SHORT, quad_indices);
}

/* ------------------------------------------------------------------ */
/* texture bookkeeping: ES has no glGetTexLevelParameteriv/GetTexImage */
/* ------------------------------------------------------------------ */
#define TEX_TABLE_SIZE 4096
static struct { GLuint id; GLint w, h; } tex_table[TEX_TABLE_SIZE];

static void tex_record(GLuint id, GLint w, GLint h)
{
	if (!id) return;
	unsigned slot = id % TEX_TABLE_SIZE, i;
	for (i = 0; i < TEX_TABLE_SIZE; i++) {
		unsigned s = (slot + i) % TEX_TABLE_SIZE;
		if (tex_table[s].id == id || tex_table[s].id == 0) {
			tex_table[s].id = id; tex_table[s].w = w; tex_table[s].h = h;
			return;
		}
	}
}

static int tex_lookup(GLuint id, GLint *w, GLint *h)
{
	unsigned slot = id % TEX_TABLE_SIZE, i;
	for (i = 0; i < TEX_TABLE_SIZE; i++) {
		unsigned s = (slot + i) % TEX_TABLE_SIZE;
		if (tex_table[s].id == id) { *w = tex_table[s].w; *h = tex_table[s].h; return 1; }
		if (tex_table[s].id == 0) break;
	}
	return 0;
}

#define TE4_GL_BGRA 0x80E1

void te4_glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void *pixels)
{
	/* ES1: internalformat must match format; BGRA sources go through
	 * GL_APPLE_texture_format_BGRA8888 (internalformat RGBA) */
	GLint ifmt = (format == GL_RGB) ? GL_RGB : GL_RGBA;
	glTexImage2D(target, level, ifmt, width, height, border, format, type, pixels);
	if (level == 0) tex_record(gl_c_texture, width, height);
}

void te4_glGetTexLevelParameteriv(GLenum target, GLint level, GLenum pname, GLint *params)
{
	GLint w = 0, h = 0;
	tex_lookup(gl_c_texture, &w, &h);
	if (pname == 0x1000 /*GL_TEXTURE_WIDTH*/) *params = w;
	else if (pname == 0x1001 /*GL_TEXTURE_HEIGHT*/) *params = h;
	else *params = 0;
}

static void bgra_swizzle(unsigned char *px, size_t n)
{
	size_t i;
	for (i = 0; i < n; i++) {
		unsigned char t = px[i * 4];
		px[i * 4] = px[i * 4 + 2];
		px[i * 4 + 2] = t;
	}
}

void te4_glReadPixels_compat(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, void *pixels)
{
	if (format == TE4_GL_BGRA) {
		glReadPixels(x, y, width, height, GL_RGBA, type, pixels);
		bgra_swizzle(pixels, (size_t)width * height);
	} else {
		glReadPixels(x, y, width, height, format, type, pixels);
	}
}

/* read a texture back through a throwaway FBO (ES has no glGetTexImage) */
void te4_glGetTexImage(GLenum target, GLint level, GLenum format, GLenum type, void *pixels)
{
	GLint w = 0, h = 0;
	if (!tex_lookup(gl_c_texture, &w, &h) || !w || !h) return;

	GLint prev_fbo = 0;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &prev_fbo);
	GLuint fbo;
	glGenFramebuffersOES(1, &fbo);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, fbo);
	glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, gl_c_texture, 0);

	if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) == GL_FRAMEBUFFER_COMPLETE_OES) {
		if (format == GL_RGB || format == 0x80E0 /*GL_BGR*/) {
			/* caller wants tightly packed 3-byte pixels; read RGBA, repack */
			int swap = (format != GL_RGB);
			unsigned char *tmp = malloc((size_t)w * h * 4);
			glReadPixels(0, 0, w, h, GL_RGBA, type, tmp);
			unsigned char *dst = pixels;
			size_t i, n = (size_t)w * h;
			for (i = 0; i < n; i++) {
				dst[i * 3] = tmp[i * 4 + (swap ? 2 : 0)];
				dst[i * 3 + 1] = tmp[i * 4 + 1];
				dst[i * 3 + 2] = tmp[i * 4 + (swap ? 0 : 2)];
			}
			free(tmp);
		} else {
			glReadPixels(0, 0, w, h, GL_RGBA, type, pixels);
			if (format == TE4_GL_BGRA) bgra_swizzle(pixels, (size_t)w * h);
		}
	}

	glBindFramebufferOES(GL_FRAMEBUFFER_OES, (GLuint)prev_fbo);
	glDeleteFramebuffersOES(1, &fbo);
}

/* ------------------------------------------------------------------ */
/* glPushAttrib(GL_VIEWPORT_BIT) / glPopAttrib                        */
/* ------------------------------------------------------------------ */
static GLint viewport_stack[8][4];
static int viewport_sp = 0;

void te4_glPushAttrib(GLbitfield mask)
{
	(void)mask; /* engine only ever saves the viewport */
	if (viewport_sp < 8) glGetIntegerv(GL_VIEWPORT, viewport_stack[viewport_sp]);
	viewport_sp++;
}

void te4_glPopAttrib(void)
{
	if (viewport_sp > 0 && viewport_sp <= 8) {
		GLint *v = viewport_stack[viewport_sp - 1];
		glViewport(v[0], v[1], v[2], v[3]);
	}
	if (viewport_sp > 0) viewport_sp--;
}

/* ------------------------------------------------------------------ */
/* desktop-only entry points reachable only behind capability flags   */
/* ------------------------------------------------------------------ */
void te4_glTexImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const void *pixels)
{
	static int warned = 0;
	if (!warned++) printf("[GLES1] glTexImage3D unsupported, 3D noise textures disabled\n");
}

void te4_glDrawBuffers(GLsizei n, const GLenum *bufs) { }

GLhandleARB te4_stub_CreateShaderObjectARB(GLenum shaderType) { return 0; }
GLhandleARB te4_stub_CreateProgramObjectARB(void) { return 0; }
void te4_stub_ShaderSourceARB(GLhandleARB s, GLsizei c, const GLcharARB **str, const GLint *l) { }
void te4_stub_CompileShaderARB(GLhandleARB s) { }
void te4_stub_LinkProgramARB(GLhandleARB p) { }
void te4_stub_AttachObjectARB(GLhandleARB c, GLhandleARB o) { }
void te4_stub_DetachObjectARB(GLhandleARB c, GLhandleARB o) { }
void te4_stub_DeleteObjectARB(GLhandleARB o) { }
void te4_stub_UseProgramObjectARB(GLhandleARB p) { }
GLint te4_stub_GetUniformLocationARB(GLhandleARB p, const GLcharARB *n) { return -1; }
void te4_stub_GetObjectParameterivARB(GLhandleARB o, GLenum pn, GLint *pa) { if (pa) *pa = 0; }
void te4_stub_GetActiveUniformARB(GLhandleARB p, GLuint i, GLsizei ml, GLsizei *l, GLint *sz, GLenum *t, GLcharARB *n) { if (l) *l = 0; if (n && ml > 0) n[0] = 0; }
void te4_stub_Uniform1fvARB(GLint l, GLsizei c, const GLfloat *v) { }
void te4_stub_Uniform2fvARB(GLint l, GLsizei c, const GLfloat *v) { }
void te4_stub_Uniform3fvARB(GLint l, GLsizei c, const GLfloat *v) { }
void te4_stub_Uniform4fvARB(GLint l, GLsizei c, const GLfloat *v) { }
void te4_stub_Uniform1ivARB(GLint l, GLsizei c, const GLint *v) { }

/* ------------------------------------------------------------------ */
/* GLU replacement: error strings + the boot-screen planet sphere     */
/* ------------------------------------------------------------------ */
struct te4_GLUquadric { int unused; };
typedef struct te4_GLUquadric GLUquadric;

GLUquadric *te4_gluNewQuadric(void) { return malloc(sizeof(GLUquadric)); }
void te4_gluDeleteQuadric(GLUquadric *q) { free(q); }
void te4_gluQuadricNormals(GLUquadric *q, GLenum normals) { }
void te4_gluQuadricTexture(GLUquadric *q, GLboolean texture) { }
const GLubyte *te4_gluErrorString(GLenum error)
{
	static char buf[32];
	snprintf(buf, sizeof(buf), "GL error 0x%x", (unsigned)error);
	return (const GLubyte *)buf;
}

/* UV sphere as one triangle-strip per stack, gluSphere-compatible
 * orientation (poles on +/-Z, texture wrapped around) */
void te4_gluSphere(GLUquadric *q, GLdouble radius, GLint slices, GLint stacks)
{
	if (slices < 3) slices = 3;
	if (stacks < 2) stacks = 2;

	int strip_verts = (slices + 1) * 2;
	GLfloat *vert = malloc(strip_verts * 3 * sizeof(GLfloat));
	GLfloat *texc = malloc(strip_verts * 2 * sizeof(GLfloat));

	int i, j;
	for (j = 0; j < stacks; j++) {
		float phi0 = M_PI * ((float)j / stacks);
		float phi1 = M_PI * ((float)(j + 1) / stacks);
		int n = 0;
		for (i = 0; i <= slices; i++) {
			float theta = 2.0f * M_PI * ((float)i / slices);
			float ct = cosf(theta), st = sinf(theta);
			float z0 = cosf(phi0), r0 = sinf(phi0);
			float z1 = cosf(phi1), r1 = sinf(phi1);

			vert[n * 3] = (GLfloat)(radius * r0 * ct);
			vert[n * 3 + 1] = (GLfloat)(radius * r0 * st);
			vert[n * 3 + 2] = (GLfloat)(radius * z0);
			texc[n * 2] = (float)i / slices;
			texc[n * 2 + 1] = 1.0f - (float)j / stacks;
			n++;
			vert[n * 3] = (GLfloat)(radius * r1 * ct);
			vert[n * 3 + 1] = (GLfloat)(radius * r1 * st);
			vert[n * 3 + 2] = (GLfloat)(radius * z1);
			texc[n * 2] = (float)i / slices;
			texc[n * 2 + 1] = 1.0f - (float)(j + 1) / stacks;
			n++;
		}
		glVertexPointer(3, GL_FLOAT, 0, vert);
		glTexCoordPointer(2, GL_FLOAT, 0, texc);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, n);
	}

	free(vert);
	free(texc);

	/* we bypassed tgl.h's pointer caches; force the engine to re-set them */
	gl_c_vertices_ptr = NULL; gl_c_vertices_nb = 0;
	gl_c_texcoords_ptr = NULL; gl_c_texcoords_nb = 0;
	gl_c_colors_ptr = NULL; gl_c_colors_nb = 0;
}

#endif /* TE4_GLES1 */
