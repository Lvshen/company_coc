#include "skynet.h"
#include "skynet_timer.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <sys/time.h>
#include <string.h>

struct logger {
	FILE * handle;
	char fileName[256];
	int close;
	int uLogFileName;
};

struct logger *
logger_create(void) {
	struct logger * inst = skynet_malloc(sizeof(*inst));
	inst->handle = NULL;
	inst->close = 0;
	inst->uLogFileName = 0;
	memset(inst->fileName, 0 , sizeof(inst->fileName));
	return inst;
}

void
logger_release(struct logger * inst) {
	if (inst->close) {
		fclose(inst->handle);
	}
	skynet_free(inst);
}

static int
_logger(struct skynet_context * context, void *ud, int type, int session, uint32_t source, const void * msg, size_t sz) {
	//add by shenj
	time_t timer = (time_t)(skynet_gettime() / 100 + skynet_gettime_fixsec());
	struct tm* t_tm;   
	t_tm = localtime(&timer); 
	char chTime[10];
	sprintf(chTime, "%04d%02d%02d%02d", t_tm->tm_year+1900, t_tm->tm_mon+1, t_tm->tm_mday, t_tm->tm_hour);
	int uLogFileName = atoi(chTime);
	struct logger * inst = ud;
	if (inst->uLogFileName != uLogFileName)
	{
		char path[256];
		inst->uLogFileName = atoi(chTime);
		sprintf(path, "%s_%d.log", inst->fileName, inst->uLogFileName);
		inst->handle = fopen(path,"a");
	}
	struct timeval tv;
	gettimeofday(&tv, NULL);
	fprintf(inst->handle, "[%4d-%02d-%02d %02d:%02d:%02d.%06ld  :%08x] ", t_tm->tm_year+1900, t_tm->tm_mon+1, t_tm->tm_mday,
		t_tm->tm_hour, t_tm->tm_min, t_tm->tm_sec, tv.tv_usec, source);
	fwrite(msg, sz , 1, inst->handle);
	fprintf(inst->handle, "\n");
	fflush(inst->handle);
	//end
	/*
	struct logger * inst = ud;
	fprintf(inst->handle, "[:wwwwwwwwwwwwww%08x] ",source);
	fwrite(msg, sz , 1, inst->handle);
	fprintf(inst->handle, "\n");
	fflush(inst->handle);
	*/
	return 0;
}

int
logger_init(struct logger * inst, struct skynet_context *ctx, const char * parm) {
	if (parm) {
		//add by shenj in 2014/11/23
		char path[256];
		char chTime[10]; 
		struct tm* t_tm;   
		time_t timer = (time_t)(skynet_gettime() / 100 + skynet_gettime_fixsec());
		t_tm = localtime(&timer); 
		sprintf(chTime, "%04d%02d%02d%02d", t_tm->tm_year+1900, t_tm->tm_mon+1, t_tm->tm_mday, t_tm->tm_hour);
		inst->uLogFileName = atoi(chTime);
		sprintf(path, "%s_%d.log", parm, inst->uLogFileName);
		strcpy(inst->fileName, parm);
		inst->handle = fopen(path,"a");
		//printf("file name is %s", inst->fileName);
		//end
		//inst->handle = fopen(parm,"w");
		if (inst->handle == NULL) {
			return 1;
		}
		inst->close = 1;
	} else {
		inst->handle = stdout;
	}
	if (inst->handle) {
		skynet_callback(ctx, inst, _logger);
		skynet_command(ctx, "REG", ".logger");
		return 0;
	}
	return 1;
}
