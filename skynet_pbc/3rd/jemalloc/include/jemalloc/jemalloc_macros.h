#include <limits.h>
#include <strings.h>

#define	JEMALLOC_VERSION "3.6.0-18-g3541a904d6fb949f3f0aea05418ccce7cbd4b705"
#define	JEMALLOC_VERSION_MAJOR 3
#define	JEMALLOC_VERSION_MINOR 6
#define	JEMALLOC_VERSION_BUGFIX 0
#define	JEMALLOC_VERSION_NREV 18
#define	JEMALLOC_VERSION_GID "3541a904d6fb949f3f0aea05418ccce7cbd4b705"

#  define MALLOCX_LG_ALIGN(la)	(la)
#  if LG_SIZEOF_PTR == 2
#    define MALLOCX_ALIGN(a)	(ffs(a)-1)
#  else
#    define MALLOCX_ALIGN(a)						\
	 ((a < (size_t)INT_MAX) ? ffs(a)-1 : ffs(a>>32)+31)
#  endif
#  define MALLOCX_ZERO	((int)0x40)
/* Bias arena index bits so that 0 encodes "MALLOCX_ARENA() unspecified". */
#  define MALLOCX_ARENA(a)	((int)(((a)+1) << 8))

#ifdef JEMALLOC_HAVE_ATTR
#  define JEMALLOC_ATTR(s) __attribute__((s))
#  define JEMALLOC_EXPORT JEMALLOC_ATTR(visibility("default"))
#  define JEMALLOC_ALIGNED(s) JEMALLOC_ATTR(aligned(s))
#  define JEMALLOC_SECTION(s) JEMALLOC_ATTR(section(s))
#  define JEMALLOC_NOINLINE JEMALLOC_ATTR(noinline)
#elif _MSC_VER
#  define JEMALLOC_ATTR(s)
#  ifdef DLLEXPORT
#    define JEMALLOC_EXPORT __declspec(dllexport)
#  else
#    define JEMALLOC_EXPORT __declspec(dllimport)
#  endif
#  define JEMALLOC_ALIGNED(s) __declspec(align(s))
#  define JEMALLOC_SECTION(s) __declspec(allocate(s))
#  define JEMALLOC_NOINLINE __declspec(noinline)
#else
#  define JEMALLOC_ATTR(s)
#  define JEMALLOC_EXPORT
#  define JEMALLOC_ALIGNED(s)
#  define JEMALLOC_SECTION(s)
#  define JEMALLOC_NOINLINE
#endif
