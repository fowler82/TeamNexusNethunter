/*
 * SELinux services exported to the rest of the kernel.
 *
 * Author: James Morris <jmorris@redhat.com>
 *
 * Copyright (C) 2005 Red Hat, Inc., James Morris <jmorris@redhat.com>
 * Copyright (C) 2006 Trusted Computer Solutions, Inc. <dgoeddel@trustedcs.com>
 * Copyright (C) 2006 IBM Corporation, Timothy R. Chavez <tinytim@us.ibm.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2,
 * as published by the Free Software Foundation.
 */
#include <linux/module.h>
#include <linux/selinux.h>

#include "security.h"
#include "avc.h"

bool selinux_is_enabled(void)
{
#if defined(SELINUX_ALWAYS_ENFORCE) || \
	defined(SELINUX_ALWAYS_PERMISSIVE)
	return true;
#else
	return selinux_enabled;
#endif
}
EXPORT_SYMBOL_GPL(selinux_is_enabled);

bool selinux_is_enforcing(void)
{
#if defined(SELINUX_ALWAYS_ENFORCE)
	return true;
#elif defined(SELINUX_ALWAYS_PERMISSIVE)
	return false;
#else
	return selinux_enforcing;
#endif
}
EXPORT_SYMBOL_GPL(selinux_is_enforcing);