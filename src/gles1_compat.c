/*
    TE4 iOS port: fixed-function emulation over OpenGL ES 2.0.
    See gles1_compat.h for the map of what is provided and why.
*/
#ifdef TE4_GLES1

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifdef TE4_GLES_CHECK
#include "ios/GLES2/gl2.h"
#include "ios/GLES2/gl2ext.h"
#else
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#endif

typedef double GLdouble;
typedef GLuint GLhandleARB;
typedef char GLcharARB;

/* tgl.h caches; kept coherent where we touch state behind the engine */
extern int nb_draws;
extern GLuint gl_c_texture;

/* ------------------------------------------------------------------ */
/* matrix stacks                                                      */
/* ------------------------------------------------------------------ */
#define MSTACK_DEPTH 32
typedef struct { float m[16]; } mat4;

static mat4 mv_stack[MSTACK_DEPTH], pj_stack[MSTACK_DEPTH];
static int mv_sp = 0, pj_sp = 0;
static int cur_mode = 0x1700; /* GL_MODELVIEW */

static mat4 *cur_top(void)
{
	return cur_mode == 0x1701 ? &pj_stack[pj_sp] : &mv_stack[mv_sp];
}

static void mat_identity(mat4 *m)
{
	memset(m->m, 0, sizeof(m->m));
	m->m[0] = m->m[5] = m->m[10] = m->m[15] = 1.0f;
}

/* r = a * b (column-major, GL convention) */
static void mat_mul(mat4 *r, const mat4 *a, const mat4 *b)
{
	mat4 t;
	int i, j, k;
	for (i = 0; i < 4; i++) for (j = 0; j < 4; j++) {
		float s = 0;
		for (k = 0; k < 4; k++) s += a->m[k * 4 + j] * b->m[i * 4 + k];
		t.m[i * 4 + j] = s;
	}
	*r = t;
}

void te4_glMatrixMode(GLenum mode) { cur_mode = (int)mode; }
void te4_glLoadIdentity(void) { mat_identity(cur_top()); }

void te4_glPushMatrix(void)
{
	if (cur_mode == 0x1701) { if (pj_sp < MSTACK_DEPTH - 1) { pj_stack[pj_sp + 1] = pj_stack[pj_sp]; pj_sp++; } }
	else { if (mv_sp < MSTACK_DEPTH - 1) { mv_stack[mv_sp + 1] = mv_stack[mv_sp]; mv_sp++; } }
}

void te4_glPopMatrix(void)
{
	if (cur_mode == 0x1701) { if (pj_sp > 0) pj_sp--; }
	else { if (mv_sp > 0) mv_sp--; }
}

void te4_glTranslatef(GLfloat x, GLfloat y, GLfloat z)
{
	mat4 t; mat_identity(&t);
	t.m[12] = x; t.m[13] = y; t.m[14] = z;
	mat_mul(cur_top(), cur_top(), &t);
}

void te4_glScalef(GLfloat x, GLfloat y, GLfloat z)
{
	mat4 t; mat_identity(&t);
	t.m[0] = x; t.m[5] = y; t.m[10] = z;
	mat_mul(cur_top(), cur_top(), &t);
}

void te4_glRotatef(GLfloat angle, GLfloat x, GLfloat y, GLfloat z)
{
	float len = sqrtf(x * x + y * y + z * z);
	if (len < 1e-6f) return;
	x /= len; y /= len; z /= len;
	float rad = angle * (float)M_PI / 180.0f;
	float c = cosf(rad), s = sinf(rad), ic = 1.0f - c;
	mat4 t; mat_identity(&t);
	t.m[0] = x * x * ic + c;     t.m[4] = x * y * ic - z * s; t.m[8] = x * z * ic + y * s;
	t.m[1] = y * x * ic + z * s; t.m[5] = y * y * ic + c;     t.m[9] = y * z * ic - x * s;
	t.m[2] = x * z * ic - y * s; t.m[6] = y * z * ic + x * s; t.m[10] = z * z * ic + c;
	mat_mul(cur_top(), cur_top(), &t);
}

void te4_glOrtho(GLdouble l, GLdouble r, GLdouble b, GLdouble t, GLdouble n, GLdouble f)
{
	mat4 o; mat_identity(&o);
	o.m[0] = (float)(2.0 / (r - l));
	o.m[5] = (float)(2.0 / (t - b));
	o.m[10] = (float)(-2.0 / (f - n));
	o.m[12] = (float)(-(r + l) / (r - l));
	o.m[13] = (float)(-(t + b) / (t - b));
	o.m[14] = (float)(-(f + n) / (f - n));
	mat_mul(cur_top(), cur_top(), &o);
}

/* ------------------------------------------------------------------ */
/* client arrays, current color, enables                              */
/* ------------------------------------------------------------------ */
typedef struct { GLint size; GLenum type; GLsizei stride; const void *ptr; int enabled; } ArrayPtr;
static ArrayPtr arr_vertex, arr_texcoord, arr_color;
static float cur_color[4] = {1, 1, 1, 1};
static int texturing_on = 0;

void te4_glVertexPointer(GLint size, GLenum type, GLsizei stride, const void *ptr)
{ arr_vertex.size = size; arr_vertex.type = type; arr_vertex.stride = stride; arr_vertex.ptr = ptr; }
void te4_glTexCoordPointer(GLint size, GLenum type, GLsizei stride, const void *ptr)
{ arr_texcoord.size = size; arr_texcoord.type = type; arr_texcoord.stride = stride; arr_texcoord.ptr = ptr; }
void te4_glColorPointer(GLint size, GLenum type, GLsizei stride, const void *ptr)
{ arr_color.size = size; arr_color.type = type; arr_color.stride = stride; arr_color.ptr = ptr; }

void te4_glEnableClientState(GLenum array)
{
	if (array == 0x8074) arr_vertex.enabled = 1;
	else if (array == 0x8078) arr_texcoord.enabled = 1;
	else if (array == 0x8076) arr_color.enabled = 1;
}

void te4_glDisableClientState(GLenum array)
{
	if (array == 0x8074) arr_vertex.enabled = 0;
	else if (array == 0x8078) arr_texcoord.enabled = 0;
	else if (array == 0x8076) arr_color.enabled = 0;
}

void te4_glColor4f(GLfloat r, GLfloat g, GLfloat b, GLfloat a)
{ cur_color[0] = r; cur_color[1] = g; cur_color[2] = b; cur_color[3] = a; }

void te4_glEnable(GLenum cap)
{
	if (cap == GL_TEXTURE_2D) { texturing_on = 1; return; }
	if (cap == 0x806F /*GL_TEXTURE_3D*/) return;
	glEnable(cap);
}

void te4_glDisable(GLenum cap)
{
	if (cap == GL_TEXTURE_2D) { texturing_on = 0; return; }
	if (cap == 0x806F) return;
	glDisable(cap);
}

/* ------------------------------------------------------------------ */
/* the pipeline shader                                                */
/* ------------------------------------------------------------------ */
#define ATTR_POS 0
#define ATTR_TEX 1
#define ATTR_COL 2

static GLuint pipe_prog = 0;
static GLint u_mvp = -1, u_tex = -1, u_use_tex = -1;

static const char *pipe_vs =
	"attribute vec4 a_pos;\n"
	"attribute vec2 a_tex;\n"
	"attribute vec4 a_col;\n"
	"uniform mat4 u_mvp;\n"
	"varying vec2 v_tex;\n"
	"varying vec4 v_col;\n"
	"void main() {\n"
	"  gl_Position = u_mvp * a_pos;\n"
	"  v_tex = a_tex;\n"
	"  v_col = a_col;\n"
	"}\n";

static const char *pipe_fs =
	"precision mediump float;\n"
	"varying vec2 v_tex;\n"
	"varying vec4 v_col;\n"
	"uniform sampler2D u_tex;\n"
	"uniform int u_use_tex;\n"
	"void main() {\n"
	"  vec4 c = v_col;\n"
	"  if (u_use_tex != 0) c *= texture2D(u_tex, v_tex);\n"
	"  gl_FragColor = c;\n"
	"}\n";

static GLuint compile_stage(GLenum kind, const char *src)
{
	GLuint sh = glCreateShader(kind);
	glShaderSource(sh, 1, &src, NULL);
	glCompileShader(sh);
	GLint ok = 0;
	glGetShaderiv(sh, GL_COMPILE_STATUS, &ok);
	if (!ok) {
		char log[512];
		glGetShaderInfoLog(sh, sizeof(log), NULL, log);
		printf("[GLES2-FF] shader compile failed: %s\n", log);
	}
	return sh;
}

void te4_gles_init(void)
{
	if (pipe_prog) return;
	mat_identity(&mv_stack[0]);
	mat_identity(&pj_stack[0]);
	GLuint vs = compile_stage(GL_VERTEX_SHADER, pipe_vs);
	GLuint fs = compile_stage(GL_FRAGMENT_SHADER, pipe_fs);
	pipe_prog = glCreateProgram();
	glAttachShader(pipe_prog, vs);
	glAttachShader(pipe_prog, fs);
	glBindAttribLocation(pipe_prog, ATTR_POS, "a_pos");
	glBindAttribLocation(pipe_prog, ATTR_TEX, "a_tex");
	glBindAttribLocation(pipe_prog, ATTR_COL, "a_col");
	glLinkProgram(pipe_prog);
	GLint ok = 0;
	glGetProgramiv(pipe_prog, GL_LINK_STATUS, &ok);
	if (!ok) {
		char log[512];
		glGetProgramInfoLog(pipe_prog, sizeof(log), NULL, log);
		printf("[GLES2-FF] program link failed: %s\n", log);
	}
	glDeleteShader(vs);
	glDeleteShader(fs);
	u_mvp = glGetUniformLocation(pipe_prog, "u_mvp");
	u_tex = glGetUniformLocation(pipe_prog, "u_tex");
	u_use_tex = glGetUniformLocation(pipe_prog, "u_use_tex");
	printf("[GLES2-FF] pipeline shader ready (prog=%u)\n", (unsigned)pipe_prog);
}

/* ------------------------------------------------------------------ */
/* draws: bind captured fixed-function state, then draw               */
/* ------------------------------------------------------------------ */
#define TE4_GL_QUADS 0x0007
#define TE4_MAX_QUAD_VERTS 65532  /* ushort index space, multiple of 4 */

static GLushort *quad_indices = NULL;
static GLsizei quad_indices_built_for = 0;

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

static void bind_pipeline(void)
{
	if (!pipe_prog) te4_gles_init();
	glUseProgram(pipe_prog);

	mat4 mvp;
	mat_mul(&mvp, &pj_stack[pj_sp], &mv_stack[mv_sp]);
	glUniformMatrix4fv(u_mvp, 1, GL_FALSE, mvp.m);

	glVertexAttribPointer(ATTR_POS, arr_vertex.size, arr_vertex.type, GL_FALSE, arr_vertex.stride, arr_vertex.ptr);
	glEnableVertexAttribArray(ATTR_POS);

	int use_tex = texturing_on && arr_texcoord.enabled && arr_texcoord.ptr;
	if (use_tex) {
		glVertexAttribPointer(ATTR_TEX, arr_texcoord.size, arr_texcoord.type, GL_FALSE, arr_texcoord.stride, arr_texcoord.ptr);
		glEnableVertexAttribArray(ATTR_TEX);
	} else {
		glDisableVertexAttribArray(ATTR_TEX);
		glVertexAttrib2f(ATTR_TEX, 0, 0);
	}
	glUniform1i(u_use_tex, use_tex);
	glUniform1i(u_tex, 0);

	if (arr_color.enabled && arr_color.ptr) {
		glVertexAttribPointer(ATTR_COL, arr_color.size, arr_color.type,
			arr_color.type == GL_UNSIGNED_BYTE ? GL_TRUE : GL_FALSE, arr_color.stride, arr_color.ptr);
		glEnableVertexAttribArray(ATTR_COL);
	} else {
		glDisableVertexAttribArray(ATTR_COL);
		glVertexAttrib4fv(ATTR_COL, cur_color);
	}
}

void te4_glDrawArrays(GLenum mode, GLint first, GLsizei count)
{
	nb_draws++;
	bind_pipeline();
	if (mode != TE4_GL_QUADS) {
		glDrawArrays(mode, first, count);
		return;
	}
	if (first != 0) {
		GLint q;
		for (q = 0; q < count / 4; q++) glDrawArrays(GL_TRIANGLE_FAN, first + q * 4, 4);
		return;
	}
	if (count > TE4_MAX_QUAD_VERTS) {
		static int warned = 0;
		if (!warned++) printf("[GLES2-FF] clamping quad draw of %d verts to %d\n", (int)count, TE4_MAX_QUAD_VERTS);
		count = TE4_MAX_QUAD_VERTS;
	}
	ensure_quad_indices(count);
	glDrawElements(GL_TRIANGLES, (count / 4) * 6, GL_UNSIGNED_SHORT, quad_indices);
}

/* ------------------------------------------------------------------ */
/* texture bookkeeping: ES lacks glGetTexLevelParameteriv/GetTexImage */
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
#define TE4_GL_BGR 0x80E0

void te4_glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void *pixels)
{
	/* ES2: internalformat must equal format, and BGRA needs the APPLE/EXT
	 * extension with internalformat RGBA on iOS -- but the simulator's GL
	 * is picky, so swizzle BGRA to RGBA CPU-side for safety. */
	if (format == TE4_GL_BGRA && pixels) {
		size_t n = (size_t)width * height;
		unsigned char *tmp = malloc(n * 4);
		const unsigned char *src = pixels;
		size_t i;
		for (i = 0; i < n; i++) {
			tmp[i * 4] = src[i * 4 + 2];
			tmp[i * 4 + 1] = src[i * 4 + 1];
			tmp[i * 4 + 2] = src[i * 4];
			tmp[i * 4 + 3] = src[i * 4 + 3];
		}
		glTexImage2D(target, level, GL_RGBA, width, height, border, GL_RGBA, type, tmp);
		free(tmp);
	} else if (format == TE4_GL_BGRA) {
		glTexImage2D(target, level, GL_RGBA, width, height, border, GL_RGBA, type, NULL);
	} else {
		GLint ifmt = (format == GL_RGB) ? GL_RGB : (GLint)format;
		glTexImage2D(target, level, ifmt, width, height, border, format, type, pixels);
	}
	if (level == 0) tex_record(gl_c_texture, width, height);
}

/* ES2 rejects BGRA sub-uploads into RGBA textures; the minimap and the
 * seens (fog) textures update through this path with GL_BGRA every frame,
 * so without this they never get written (stale VRAM showed as a "rat") */
void te4_glTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const void *pixels)
{
	if (format == TE4_GL_BGRA && pixels) {
		size_t n = (size_t)width * height;
		unsigned char *tmp = malloc(n * 4);
		const unsigned char *src = pixels;
		size_t i;
		for (i = 0; i < n; i++) {
			tmp[i * 4] = src[i * 4 + 2];
			tmp[i * 4 + 1] = src[i * 4 + 1];
			tmp[i * 4 + 2] = src[i * 4];
			tmp[i * 4 + 3] = src[i * 4 + 3];
		}
		glTexSubImage2D(target, level, xoffset, yoffset, width, height, GL_RGBA, type, tmp);
		free(tmp);
		return;
	}
	glTexSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
}

void te4_glGetTexLevelParameteriv(GLenum target, GLint level, GLenum pname, GLint *params)
{
	GLint w = 0, h = 0;
	tex_lookup(gl_c_texture, &w, &h);
	if (pname == 0x1000) *params = w;
	else if (pname == 0x1001) *params = h;
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
	/* ES2 glReadPixels only guarantees GL_RGBA/GL_UNSIGNED_BYTE; the engine's
	 * screenshot path asks for 3-byte RGB/BGR (came back black on iOS) */
	if (format == TE4_GL_BGRA) {
		glReadPixels(x, y, width, height, GL_RGBA, type, pixels);
		bgra_swizzle(pixels, (size_t)width * height);
	} else if (format == GL_RGB || format == TE4_GL_BGR) {
		int swap = (format != GL_RGB);
		size_t n = (size_t)width * height;
		unsigned char *tmp = malloc(n * 4);
		glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, tmp);
		unsigned char *dst = pixels;
		size_t i;
		for (i = 0; i < n; i++) {
			dst[i * 3] = tmp[i * 4 + (swap ? 2 : 0)];
			dst[i * 3 + 1] = tmp[i * 4 + 1];
			dst[i * 3 + 2] = tmp[i * 4 + (swap ? 0 : 2)];
		}
		free(tmp);
	} else {
		glReadPixels(x, y, width, height, format, type, pixels);
	}
}

void te4_glGetTexImage(GLenum target, GLint level, GLenum format, GLenum type, void *pixels)
{
	GLint w = 0, h = 0;
	if (!tex_lookup(gl_c_texture, &w, &h) || !w || !h) return;

	GLint prev_fbo = 0;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prev_fbo);
	GLuint fbo;
	glGenFramebuffers(1, &fbo);
	glBindFramebuffer(GL_FRAMEBUFFER, fbo);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, gl_c_texture, 0);

	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE) {
		if (format == GL_RGB || format == TE4_GL_BGR) {
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

	glBindFramebuffer(GL_FRAMEBUFFER, (GLuint)prev_fbo);
	glDeleteFramebuffers(1, &fbo);
}

/* ------------------------------------------------------------------ */
/* default framebuffer: on iOS the screen is an FBO, never id 0       */
/* ------------------------------------------------------------------ */
GLuint te4_gles1_default_fbo = 0;

void te4_gles1_capture_default_fbo(void)
{
	GLint fb = 0;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING, &fb);
	te4_gles1_default_fbo = (GLuint)fb;
	printf("[GLES2-FF] default framebuffer = %u, GL_VERSION: %s\n",
		(unsigned)te4_gles1_default_fbo, (const char*)glGetString(GL_VERSION));
	te4_gles_init();
}

void te4_glBindFramebuffer(GLenum target, GLuint framebuffer)
{
	glBindFramebuffer(target, framebuffer ? framebuffer : te4_gles1_default_fbo);
}

/* ------------------------------------------------------------------ */
/* viewport-only attrib stack                                         */
/* ------------------------------------------------------------------ */
static GLint viewport_stack[8][4];
static int viewport_sp = 0;

void te4_glPushAttrib(GLbitfield mask)
{
	(void)mask;
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
/* misc no-ops / renames                                              */
/* ------------------------------------------------------------------ */
void te4_glClearDepth(GLdouble d) { glClearDepthf((GLclampf)d); }

/* multitexture is reported unavailable, but track unit switches anyway:
 * the pipeline shader only samples unit 0, so a bind on another unit
 * would silently leave a stale texture on unit 0 */
static GLenum cur_tex_unit = GL_TEXTURE0;
void te4_glActiveTexture(GLenum unit)
{
	static int warned = 0;
	if (unit != GL_TEXTURE0 && warned < 5) {
		warned++;
		printf("[GLES2-FF] glActiveTexture(0x%x) with multitexture off\n", (unsigned)unit);
	}
	cur_tex_unit = unit;
	glActiveTexture(unit);
}

void te4_glTexImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const void *pixels)
{
	static int warned = 0;
	if (!warned++) printf("[GLES2-FF] glTexImage3D unsupported, 3D noise textures disabled\n");
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
void te4_stub_GetInfoLogARB(GLhandleARB o, GLsizei ml, GLsizei *l, GLcharARB *log) { if (l) *l = 0; if (log && ml > 0) log[0] = 0; }
void te4_stub_ValidateProgramARB(GLhandleARB p) { }

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
 * orientation; drawn through the emulated pipeline */
void te4_gluSphere(GLUquadric *q, GLdouble radius, GLint slices, GLint stacks)
{
	if (slices < 3) slices = 3;
	if (stacks < 2) stacks = 2;

	int strip_verts = (slices + 1) * 2;
	GLfloat *vert = malloc(strip_verts * 3 * sizeof(GLfloat));
	GLfloat *texc = malloc(strip_verts * 2 * sizeof(GLfloat));

	ArrayPtr save_v = arr_vertex, save_t = arr_texcoord, save_c = arr_color;

	int i, j;
	for (j = 0; j < stacks; j++) {
		float phi0 = (float)M_PI * ((float)j / stacks);
		float phi1 = (float)M_PI * ((float)(j + 1) / stacks);
		int n = 0;
		for (i = 0; i <= slices; i++) {
			float theta = 2.0f * (float)M_PI * ((float)i / slices);
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
		te4_glVertexPointer(3, GL_FLOAT, 0, vert);
		te4_glTexCoordPointer(2, GL_FLOAT, 0, texc);
		te4_glDrawArrays(GL_TRIANGLE_STRIP, 0, n);
	}

	arr_vertex = save_v; arr_texcoord = save_t; arr_color = save_c;
	free(vert);
	free(texc);
}

#endif /* TE4_GLES1 */
