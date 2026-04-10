from typing import TypedDict, Optional, Any

from flask import request
from ldap3 import Server, Connection, ALL, SUBTREE
from ldap3.core.exceptions import LDAPException, LDAPSocketOpenError, LDAPBindError
import logging

logger = logging.getLogger(__name__)


class ResultType(TypedDict):
    status: bool
    error: Optional[str]  # None o cualquier otro tipo que uses
    attributes: dict[Any, Any]


class LDAPAuthenticator:
    def __init__(self, server_url="ldaps://ldap.ine.es"):
        self.server = Server(server_url, use_ssl=True, get_info=ALL)
        self.base_dn = "ou=Personal,dc=ine,dc=es"

    def authenticate(self, username, password):

        result: ResultType = {"status": False, "error": None, "attributes": {}}

        try:
            # 1. Conexión inicial para buscar el DN
            try:
                logger.debug("Intentando conexión anónima al servidor LDAP para buscar DN…")
                search_conn = Connection(self.server, auto_bind=True)
            except LDAPSocketOpenError as e:
                msg = f"Error de conexión con servidor LDAP: {e}"
                logger.error(msg)
                result["error"] = msg
                return result

            # Buscar el DN del usuario y atributos
            logger.debug(f"Buscando DN para uid='{username}' en LDAP...")
            search_conn.search(
                search_base=self.base_dn,
                search_filter=f"(uid={username})",
                search_scope=SUBTREE,
                attributes=['cn', 'displayName', 'givenName', 'sn', 'mail']  # atributos que quieres
            )

            if not search_conn.entries:
                msg = f"Usuario '{username}' no encontrado en el LDAP"
                logger.warning(msg)
                result["error"] = msg
                return result

            # DN real del usuario
            user_entry = search_conn.entries[0]
            user_dn = user_entry.entry_dn
            logger.info(f"DN encontrado para {username}: {user_dn}")

            # Guardar atributos en el resultado
            result["attributes"] = user_entry.entry_attributes_as_dict

            # 2. Intentar bind con DN + contraseña
            try:
                logger.debug(f"Intentando bind para el usuario {username} con DN {user_dn}…")
                #Se ignora el retorno porque no se usa (variable ignorada)
                _ = Connection(
                    self.server,
                    user=user_dn,
                    password=password,
                    auto_bind=True
                )

                # Registrar login
                logger.info(
                    f"Login de usuario {username} desde la IP {request.remote_addr}, "
                    f"User-Agent: {request.headers.get('User-Agent')}"
                )

                result["status"] = True
                return result

            except (LDAPBindError, LDAPException) as e:
                msg = f"Credenciales inválidas para usuario {username}: {e}"
                logger.warning(msg)
                result["error"] = msg
                return result

        except Exception as e:
            msg = f"Error inesperado autenticando usuario {username}: {e}"
            logger.exception(msg)
            result["error"] = msg
            return result

