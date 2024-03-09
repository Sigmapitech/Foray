#define _GNU_SOURCE

#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "foray.h"

static const char LD_PRELOAD[] = "LD_PRELOAD=%s";
static const char LIB_NAME[] = "libforay.so";

static
char *get_lib_path(char const *ldpath)
{
    static char file[PATH_MAX] = { 0 };
    char const *path = ldpath;
    size_t len = strcspn(ldpath, ":");
    char *buff;

    for (; *path != '\0'; path += len + 1) {
        memcpy(file, path, len);
        if (file[len - 1] != '/')
            file[len++] = '/';

        memcpy(file + len, sstr_unpack(LIB_NAME));
        file[len + length_of(LIB_NAME)] = '\0';

        if (!access(file, F_OK)) {
            asprintf(&buff, LD_PRELOAD, file);
            printf("[%s]\n", buff);
            return buff;
        }
    }

    write(STDERR_FILENO, sstr_unpack("libforay not found\n"));
    return NULL;
}

static
bool ld_preload_set(char **env, size_t nmemb)
{
    char *ldpath = getenv("LD_LIBRARY_PATH");
    char default_ldpath[] = ".";

    if (ldpath == NULL) {
        write(STDERR_FILENO,
            sstr_unpack("LD_LIBRARY_PATH == NULL, trying .\n"));
        ldpath = default_ldpath;
    }
    env[nmemb] = get_lib_path(ldpath);
    if (env[nmemb] == NULL)
        return false;
    env[nmemb + 1] = NULL;
    return true;
}

static
bool ld_preload_bin(char **env, char **argv)
{
    size_t nmemb = 0;
    char **envp;

    for (; env[nmemb] != NULL; ++nmemb);
    envp = reallocarray(NULL, nmemb + 1, sizeof *env);
    if (envp == NULL) {
        write(STDERR_FILENO, sstr_unpack("envp allocation failure\n"));
        return false;
    }

    memcpy(envp, env, nmemb * sizeof *env);
    if (!ld_preload_set(envp, nmemb)) {
        free(envp);
        return false;
    }

    execvpe(argv[0], argv, envp);
    return true;
}

int main(int argc, char **argv, char **env)
{
    if (argc < 2)
        return EXIT_FAILURE;
    if (!ld_preload_bin(env, argv + 1))
        return EXIT_FAILURE;
    return EXIT_SUCCESS;
}
