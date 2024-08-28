"""This module contains functions which orchestrate the other modules so that they don't need to call each other."""
import logging
import re
from .errors import HelmReleaseNotFoundError
from .workdir import Workdir
from .helm import Helm

LOG = logging.getLogger(__name__)


def install_or_upgrade_iccr_crd(skip_crds, crd_namespace, iccr_crd_helm_release_name):
    """Install the ICCR CRD chart if not present in the cluster. Upgrade it if we have a newer version."""
    if skip_crds:
        LOG.info("Skipping ICCR CRD install/upgrade as requested.")
        return

    workdir = Workdir()
    helm = Helm(kubernetes_config_file_path=workdir.kube_config_file_path, namespace=crd_namespace)
    crd_chart_path = workdir.get_a_csar().get_chart_path(chart_is_crd=True)
    try:
        crd_helm_release_version = helm.get_release_chart_version(release_name=iccr_crd_helm_release_name)
        crd_helm_release_found = True
    except HelmReleaseNotFoundError:
        crd_helm_release_found = False

    if crd_helm_release_found is False:
        LOG.info("Started installing the ICCR CRD chart because no previously installed helm release was found.")
        helm.install(release_name=iccr_crd_helm_release_name, chart_path=crd_chart_path, timeout='5m',
                     extra_helm_args_list=['--set', 'rbac.create=true', '--atomic'],
                                         site_values_file_path=workdir.site_values_file_path)
        LOG.info("Completed installing the ICCR CRD chart.")
    else:
        crd_chart_version = workdir.get_a_csar().get_chart_version(chart_is_crd=True)
        crd_chart_version_tuple = tuple(map(int, re.split('\\.|\\-|\\+', crd_chart_version)))
        crd_helm_release_version_tuple = tuple(map(int, re.split('\\.|\\-|\\+', crd_helm_release_version)))

        if crd_chart_version_tuple > crd_helm_release_version_tuple:
            LOG.info("Started upgrading the ICCR CRD from version " + crd_helm_release_version + ' to version ' +
                     crd_chart_version)
            helm.upgrade(release_name=iccr_crd_helm_release_name, chart_path=crd_chart_path, timeout='5m',
                         extra_helm_args_list=['--set', 'rbac.create=true', '--atomic'],
                                                 site_values_file_path=workdir.site_values_file_path)
            LOG.info("Completed upgrading the ICCR CRD from version " + crd_helm_release_version + ' to version ' +
                     crd_chart_version)
        else:
            LOG.info("Not upgrading the ICCR CRD because the version in the chart " + crd_chart_version +
                     " is not newer than what's deployed " + crd_helm_release_version)